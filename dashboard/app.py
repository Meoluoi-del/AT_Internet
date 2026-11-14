import os
import secrets
import urllib.parse
import time
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify, abort, g
from flask.sessions import SessionInterface, SessionMixin
from config import Config
from ldap_client import LDAPClient
from models import DBManager, get_db_connection
from detector import detector_instance
from mfa import generate_secret, get_totp_code, verify_totp, verify_totp_detailed, get_totp_uri
from sso import create_jwt, verify_jwt

app = Flask(__name__)
app.config.from_object(Config)

# ====================================================================
# MULTI-TAB SESSION ISOLATION (HỖ TRỢ ĐĂNG NHẬP NHIỀU USER TRÊN CÁC TAB KHÁC NHAU)
# ====================================================================
class TabSession(dict, SessionMixin):
    def __init__(self, sid, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sid = sid
        self.modified = False

class TabSessionInterface(SessionInterface):
    """Lưu trữ session độc lập theo Tab Session ID (sid) trên server."""
    def __init__(self):
        self.store = {}

    def _extract_sid(self, request):
        sid = request.args.get('sid') or request.form.get('sid') or getattr(g, 'sid', None)
        if not sid and request.referrer:
            try:
                parsed_ref = urllib.parse.urlparse(request.referrer)
                qs = urllib.parse.parse_qs(parsed_ref.query)
                if 'sid' in qs and qs['sid']:
                    sid = qs['sid'][0]
            except Exception:
                pass
        if sid and isinstance(sid, str):
            sid = sid.split('?')[0].split('&')[0].strip()
        return sid

    def open_session(self, app, request):
        sid = self._extract_sid(request)
        if not sid:
            # Không có sid -> luôn tạo session mới rỗng (chưa đăng nhập)
            sid = secrets.token_hex(6)
            s = TabSession(sid)
            self.store[sid] = s
            return s
        if sid not in self.store:
            # sid không tồn tại trong store -> tạo session mới rỗng, không thừa kế
            self.store[sid] = TabSession(sid)
        return self.store[sid]

    def save_session(self, app, session, response):
        if hasattr(session, 'sid'):
            self.store[session.sid] = session

app.session_interface = TabSessionInterface()

@app.before_request
def handle_tab_session():
    # Bỏ qua các file tĩnh và icon
    if request.endpoint == 'static' or request.path.startswith('/static') or request.path == '/favicon.ico':
        return

    sid = request.args.get('sid') or request.form.get('sid')
    if not sid and request.referrer:
        try:
            parsed_ref = urllib.parse.urlparse(request.referrer)
            qs = urllib.parse.parse_qs(parsed_ref.query)
            if 'sid' in qs and qs['sid']:
                sid = qs['sid'][0]
        except Exception:
            pass

    if sid and isinstance(sid, str):
        sid = sid.split('?')[0].split('&')[0].strip()

    if not sid:
        # Không có sid -> tạo sid mới, không bao giờ thừa kế session người khác
        if request.method == 'GET':
            new_sid = secrets.token_hex(6)
            args = request.args.to_dict()
            args['sid'] = new_sid
            query_str = urllib.parse.urlencode(args)
            return redirect(f"{request.path}?{query_str}")
        else:
            g.sid = secrets.token_hex(6)
            return

    g.sid = sid

@app.url_defaults
def add_sid_to_urls(endpoint, values):
    """Tự động đính kèm sid vào mọi link url_for() sinh ra trong template."""
    if endpoint == 'static':
        return
    if 'sid' not in values and hasattr(g, 'sid') and g.sid:
        values['sid'] = g.sid

ldap_client = LDAPClient()

# Start Active Defense Background Detector
detector_instance.start()

# Hardcoded administrative users for Dashboard access control
ADMIN_USERS = {
    'admin': {'password': 'AdminPassword123!', 'role': 'admin', 'name': 'Quản Trị Viên Toàn Quyền'},
    'auditor': {'password': 'AuditorPass123!', 'role': 'auditor', 'name': 'Cán Bộ Kiểm Toán An Toàn'}
}

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            if request.path.startswith('/api/'):
                return jsonify({'status': 'error', 'message': 'Unauthorized'}), 401
            flash('Vui lòng đăng nhập để tiếp tục truy cập.', 'warning')
            return redirect(url_for('login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'admin':
            if request.is_json or request.method in ['POST', 'PUT', 'DELETE']:
                abort(403)
            flash('Từ chối quyền truy cập! Vai trò Kiểm toán (Auditor) chỉ được xem, không được chỉnh sửa.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

@app.context_processor
def inject_global_data():
    return {
        'sid': getattr(g, 'sid', ''),
        'current_user': session.get('username', ''),
        'current_role': session.get('role', ''),
        'active_alerts': detector_instance.recent_alerts
    }

# ==========================================================
# AUTHENTICATION & MULTI-TAB ROUTES
# ==========================================================
@app.route('/new-tab')
def new_tab():
    """Tạo một phiên tab mới với Session ID độc lập và mở trang đăng nhập."""
    new_sid = secrets.token_hex(6)
    return redirect(url_for('login', sid=new_sid))
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()

        # Check local dashboard admin/auditor accounts
        if username in ADMIN_USERS and ADMIN_USERS[username]['password'] == password:
            # 1. Kiểm tra trạng thái Xác thực đa nhân tố (MFA / 2FA)
            mfa_record = DBManager.get_user_mfa(username)
            if mfa_record and mfa_record.get('is_enabled') == 1:
                lock_info = DBManager.check_mfa_lock(username)
                if lock_info['is_locked']:
                    flash(f'Tài khoản {username} đang bị tạm khóa xác thực MFA do nhập sai quá 3 lần. Vui lòng thử lại sau {lock_info["minutes_left"]} phút!', 'danger')
                    return redirect(url_for('login'))

                session['mfa_pending'] = True
                session['mfa_username'] = username
                session['mfa_role'] = ADMIN_USERS[username]['role']
                session['mfa_name'] = ADMIN_USERS[username]['name']
                session['mfa_next'] = request.args.get('next', '')
                flash('Mật khẩu hợp lệ! Vui lòng nhập mã xác thực OTP 6 số từ ứng dụng Authenticator (MFA Step 2).', 'info')
                return redirect(url_for('mfa_verify'))

            # Đăng nhập trực tiếp nếu chưa bật MFA
            session['logged_in'] = True
            session['username'] = username
            session['role'] = ADMIN_USERS[username]['role']
            session['display_name'] = ADMIN_USERS[username]['name']
            
            DBManager.add_audit_log(
                actor=username,
                action="DASHBOARD_LOGIN",
                target="SYSTEM",
                new_value=f"Login success as {session['role']}",
                ip=request.remote_addr
            )
            flash(f'Chào mừng {session["display_name"]} đăng nhập thành công!', 'success')
            next_url = request.args.get('next')
            if next_url and next_url.startswith('/') and not next_url.startswith('/login'):
                return redirect(next_url)
            return redirect(url_for('index'))
        else:
            flash('Sai tên đăng nhập hoặc mật khẩu! Vui lòng thử lại.', 'danger')

    return render_template('login.html')

@app.route('/mfa/verify', methods=['GET', 'POST'])
def mfa_verify():
    """Xác thực Bước 2 bằng mã TOTP 6 số từ Authenticator."""
    if not session.get('mfa_pending') or not session.get('mfa_username'):
        flash('Không có phiên xác thực MFA đang chờ. Vui lòng đăng nhập.', 'warning')
        return redirect(url_for('login'))
    
    username = session.get('mfa_username')
    mfa_record = DBManager.get_user_mfa(username)
    if not mfa_record or not mfa_record.get('is_enabled'):
        session.pop('mfa_pending', None)
        return redirect(url_for('login'))

    lock_info = DBManager.check_mfa_lock(username)

    if request.method == 'POST':
        if lock_info['is_locked']:
            flash(f"Tài khoản đang bị tạm khóa xác thực MFA do nhập sai quá 3 lần! Vui lòng thử lại sau {lock_info['minutes_left']} phút.", 'danger')
            return render_template('mfa_verify.html', username=username, lock_info=lock_info)

        code = request.form.get('code', '').strip()
        last_step = mfa_record.get('last_verified_step')
        is_valid, reason, matched_step = verify_totp_detailed(
            mfa_record['secret_key'], code, last_verified_step=last_step
        )

        if reason == 'REPLAY':
            # Chống dùng lại mã (Replay Protection theo RFC 6238)
            DBManager.add_audit_log(
                actor=username,
                action="MFA_REPLAY_ATTEMPT",
                target="SYSTEM",
                old_val=f"Replayed OTP code: {code}",
                ip=request.remote_addr
            )
            flash('Mã xác thực này đã được sử dụng trước đó! Vui lòng đợi mã mới (chu kỳ 30 giây tiếp theo) trên ứng dụng Authenticator.', 'warning')
            return render_template('mfa_verify.html', username=username, lock_info=lock_info)

        elif is_valid:
            # Xác thực 2 lớp thành công!
            role = session.get('mfa_role', 'admin')
            display_name = session.get('mfa_name', username)
            next_url = session.get('mfa_next')

            session.pop('mfa_pending', None)
            session.pop('mfa_username', None)
            session.pop('mfa_role', None)
            session.pop('mfa_name', None)
            session.pop('mfa_next', None)

            session['logged_in'] = True
            session['username'] = username
            session['role'] = role
            session['display_name'] = display_name
            
            # Ghi nhận thành công: reset số lần sai, xóa khóa, lưu bước thời gian vừa dùng
            DBManager.record_mfa_success(username, matched_step)
            DBManager.add_audit_log(
                actor=username,
                action="MFA_LOGIN_SUCCESS",
                target="SYSTEM",
                new_value=f"Xác thực MFA thành công qua mã TOTP 6 số cho {username} (TimeStep: {matched_step})",
                ip=request.remote_addr
            )
            flash(f'Xác thực 2 lớp (MFA) thành công! Chào mừng {display_name}.', 'success')
            if next_url and next_url.startswith('/') and not next_url.startswith('/login'):
                return redirect(next_url)
            return redirect(url_for('index'))
        else:
            # Mã không hợp lệ -> Ghi nhận lần nhập sai
            fail_info = DBManager.record_mfa_failed_attempt(username, max_attempts=3, lock_minutes=10)
            if fail_info['is_locked']:
                DBManager.add_audit_log(
                    actor=username,
                    action="MFA_LOCKED",
                    target="SYSTEM",
                    old_val=f"Nhập sai {fail_info['failed_attempts']} lần liên tiếp",
                    new_value=f"Khóa MFA trong {fail_info['lock_minutes']} phút",
                    ip=request.remote_addr
                )
                flash(f"Bạn đã nhập sai mã OTP quá 3 lần! Tài khoản bị tạm khóa xác thực MFA trong {fail_info['lock_minutes']} phút.", 'danger')
            else:
                rem = fail_info['remaining_attempts']
                DBManager.add_audit_log(
                    actor=username,
                    action="MFA_LOGIN_FAILED",
                    target="SYSTEM",
                    old_val="Invalid TOTP",
                    new_value=f"Lần sai thứ {fail_info['failed_attempts']}/3. Còn {rem} lần thử.",
                    ip=request.remote_addr
                )
                flash(f"Mã xác thực 6 chữ số không đúng! Bạn còn {rem} lần thử trước khi tài khoản bị khóa 10 phút.", 'danger')

            lock_info = DBManager.check_mfa_lock(username)
            return render_template('mfa_verify.html', username=username, lock_info=lock_info)

    return render_template('mfa_verify.html', username=username, lock_info=lock_info)

@app.route('/mfa/setup', methods=['GET', 'POST'])
@login_required
def mfa_setup():
    """Cài đặt và Quản lý Xác thực Đa nhân tố (MFA TOTP) cho tài khoản đang đăng nhập."""
    username = session.get('username')
    mfa_record = DBManager.get_user_mfa(username)

    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'enable':
            code = request.form.get('code', '').strip()
            secret = request.form.get('secret_key', '').strip()
            is_valid, reason, matched_step = verify_totp_detailed(secret, code)
            if is_valid:
                DBManager.save_user_mfa(username, secret, is_enabled=1)
                DBManager.record_mfa_success(username, matched_step)
                DBManager.add_audit_log(
                    actor=username,
                    action="ENABLE_MFA",
                    target=username,
                    new_value="Kích hoạt thành công xác thực 2 lớp TOTP (RFC 6238)",
                    ip=request.remote_addr
                )
                flash('Chúc mừng! Bạn đã kích hoạt thành công Xác thực đa nhân tố (MFA). Mọi lần đăng nhập sau sẽ yêu cầu mã OTP.', 'success')
                return redirect(url_for('mfa_setup'))
            else:
                flash('Mã OTP 6 chữ số không khớp! Vui lòng kiểm tra lại giờ hệ thống và nhập mã mới.', 'danger')
        elif action == 'disable':
            DBManager.disable_user_mfa(username)
            DBManager.add_audit_log(
                actor=username,
                action="DISABLE_MFA",
                target=username,
                old_val="Đã tắt MFA",
                ip=request.remote_addr
            )
            flash('Đã tắt Xác thực đa nhân tố (MFA) cho tài khoản của bạn.', 'warning')
            return redirect(url_for('mfa_setup'))

    # Chuẩn bị Secret Key
    if not mfa_record:
        fresh_secret = generate_secret()
        DBManager.save_user_mfa(username, fresh_secret, is_enabled=0)
        secret_key = fresh_secret
        is_enabled = False
    else:
        secret_key = mfa_record['secret_key']
        is_enabled = bool(mfa_record['is_enabled'])

    totp_uri = get_totp_uri(secret_key, username)
    return render_template('mfa_setup.html', secret_key=secret_key, is_enabled=is_enabled, totp_uri=totp_uri)

# ==========================================================
# SINGLE SIGN-ON (SSO) & OPENID CONNECT (OIDC) ENDPOINTS
# ==========================================================
@app.route('/sso/portal')
def sso_portal():
    """Cổng khởi động SSO tập trung (Unified SSO Launchpad)."""
    clients = DBManager.get_sso_clients()
    is_authenticated = session.get('logged_in', False)
    current_username = session.get('username', '')
    current_role = session.get('role', '')
    
    user_vlan = "99"
    user_group = "Chưa gán"
    if is_authenticated and current_username:
        try:
            group = ldap_client.get_user_group(current_username)
            if group:
                user_group = group
                if group == 'quantri': user_vlan = '10'
                elif group == 'sinhvien': user_vlan = '20'
                elif group == 'giangvien': user_vlan = '30'
                elif group == 'quarantine': user_vlan = '99'
            elif current_role == 'admin':
                user_group = 'quantri'
                user_vlan = '10'
            elif current_role == 'auditor':
                user_group = 'giangvien'
                user_vlan = '30'
        except Exception:
            pass

    return render_template('sso_portal.html', 
                           clients=clients, 
                           is_authenticated=is_authenticated,
                           username=current_username,
                           role=current_role,
                           user_group=user_group,
                           user_vlan=user_vlan)

@app.route('/.well-known/openid-configuration')
def oidc_discovery():
    """OpenID Connect Discovery Document (RFC 8414 / OIDC Core 1.0)."""
    base_url = request.host_url.rstrip('/')
    return jsonify({
        "issuer": f"{base_url}",
        "authorization_endpoint": f"{base_url}/oauth/authorize",
        "token_endpoint": f"{base_url}/oauth/token",
        "userinfo_endpoint": f"{base_url}/oauth/userinfo",
        "jwks_uri": f"{base_url}/oauth/jwks",
        "response_types_supported": ["code", "token", "id_token"],
        "subject_types_supported": ["public"],
        "id_token_signing_alg_values_supported": ["HS256"],
        "scopes_supported": ["openid", "profile", "email", "groups", "vlan"],
        "token_endpoint_auth_methods_supported": ["client_secret_post", "client_secret_basic"],
        "claims_supported": ["sub", "iss", "aud", "exp", "iat", "name", "email", "group", "vlan"]
    })

@app.route('/oauth/authorize', methods=['GET', 'POST'])
def oauth_authorize():
    """OAuth 2.0 Authorization Endpoint (Authorization Code Flow)."""
    client_id = request.args.get('client_id')
    redirect_uri = request.args.get('redirect_uri')
    state = request.args.get('state', '')
    
    client = DBManager.get_sso_client(client_id)
    if not client:
        return jsonify({"error": "invalid_client", "error_description": "Client ID not registered in SSO directory"}), 400

    if not session.get('logged_in'):
        return redirect(url_for('login', next=request.url))

    username = session.get('username')
    code = DBManager.create_auth_code(client_id, username, redirect_uri or client['redirect_uri'])
    
    DBManager.add_audit_log(
        actor=username,
        action="SSO_AUTHORIZE_SUCCESS",
        target=client_id,
        new_value=f"Single Sign-On access granted for client: {client['client_name']}",
        ip=request.remote_addr
    )

    target_uri = redirect_uri or client['redirect_uri']
    delim = '&' if '?' in target_uri else '?'
    return redirect(f"{target_uri}{delim}code={code}&state={state}")

@app.route('/oauth/token', methods=['POST'])
def oauth_token():
    """OAuth 2.0 Token Endpoint (Đổi Authorization Code lấy JWT Access Token & ID Token)."""
    grant_type = request.form.get('grant_type')
    code = request.form.get('code')
    client_id = request.form.get('client_id')
    client_secret = request.form.get('client_secret')

    if grant_type != 'authorization_code':
        return jsonify({"error": "unsupported_grant_type"}), 400

    client = DBManager.get_sso_client(client_id)
    if not client or client['client_secret'] != client_secret:
        return jsonify({"error": "invalid_client", "error_description": "Bad client credentials"}), 401

    auth_record = DBManager.consume_auth_code(code, client_id)
    if not auth_record:
        return jsonify({"error": "invalid_grant", "error_description": "Authorization code expired or already consumed"}), 400

    username = auth_record['username']
    group = "quantri" if username == 'admin' else (ldap_client.get_user_group(username) or "sinhvien")
    vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
    vlan = vlan_map.get(group, 99)

    token_payload = {
        "sub": username,
        "aud": client_id,
        "name": username,
        "email": f"{username}@ptit.edu.vn",
        "group": group,
        "vlan": vlan,
        "auth_time": int(time.time())
    }
    secret_key = app.config['SECRET_KEY']
    access_token = create_jwt(token_payload, secret_key, expires_in=3600)
    id_token = create_jwt(token_payload, secret_key, expires_in=3600)

    return jsonify({
        "access_token": access_token,
        "token_type": "Bearer",
        "expires_in": 3600,
        "id_token": id_token,
        "scope": "openid profile email groups vlan"
    })

@app.route('/oauth/userinfo')
def oauth_userinfo():
    """OpenID Connect UserInfo Endpoint."""
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({"error": "unauthorized", "error_description": "Bearer token required in Authorization header"}), 401
    
    token = auth_header.split(' ', 1)[1]
    try:
        claims = verify_jwt(token, app.config['SECRET_KEY'])
        return jsonify(claims)
    except Exception as e:
        return jsonify({"error": "invalid_token", "error_description": str(e)}), 401

@app.route('/sso/simulate-app/<client_id>')
def sso_simulate_app(client_id):
    """Trang mô phỏng ứng dụng đối tác sau khi nhận SSO Token thành công."""
    client = DBManager.get_sso_client(client_id)
    if not client:
        flash("Ứng dụng không tồn tại", "danger")
        return redirect(url_for('sso_portal'))

    if not session.get('logged_in'):
        return redirect(url_for('login', next=request.url))

    username = session.get('username')
    group = "quantri" if username == 'admin' else (ldap_client.get_user_group(username) or "sinhvien")
    vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
    vlan = vlan_map.get(group, 99)

    sso_token = create_jwt({
        "sub": username,
        "aud": client_id,
        "client_name": client['client_name'],
        "group": group,
        "vlan": vlan
    }, app.config['SECRET_KEY'], expires_in=3600)

    return render_template('sso_app_demo.html', client=client, username=username, group=group, vlan=vlan, token=sso_token)

@app.route('/logout')
def logout():
    actor = session.get('username', 'UNKNOWN')
    DBManager.add_audit_log(
        actor=actor,
        action="DASHBOARD_LOGOUT",
        target="SYSTEM",
        ip=request.remote_addr
    )
    session.clear()
    flash('Bạn đã đăng xuất an toàn.', 'info')
    return redirect(url_for('login'))

# ==========================================================
# DASHBOARD VIEWS
# ==========================================================
@app.route('/')
@login_required
def index():
    try:
        users = ldap_client.get_all_users()
        total_users = len(users)
        quarantined_count = sum(1 for u in users if u['group'] == 'quarantine')
    except Exception as e:
        users = []
        total_users = 0
        quarantined_count = 0

    stats = DBManager.get_stats()
    stats['total_users'] = total_users
    stats['quarantined_count'] = quarantined_count
    
    recent_logs = DBManager.get_auth_logs(limit=8)
    policies = DBManager.get_policies()

    return render_template('index.html', stats=stats, recent_logs=recent_logs, policies=policies)

@app.route('/users')
@login_required
def users_list():
    try:
        users = ldap_client.get_all_users()
    except Exception as e:
        users = []
        flash(f'Lỗi kết nối LDAP: {e}', 'danger')
    policies = DBManager.get_policies()
    initial_filter = request.args.get('filter', '').strip()
    search_query = request.args.get('search', '').strip()
    quarantined_count = sum(1 for u in users if u.get('group') == 'quarantine' or u.get('status') == 'quarantined')
    active_count = len(users) - quarantined_count
    return render_template(
        'users.html',
        users=users,
        policies=policies,
        initial_filter=initial_filter,
        search_query=search_query,
        quarantined_count=quarantined_count,
        active_count=active_count
    )

@app.route('/users/create', methods=['POST'])
@login_required
@admin_required
def user_create():
    uid = request.form.get('uid', '').strip()
    cn = request.form.get('cn', '').strip()
    sn = request.form.get('sn', '').strip()
    mail = request.form.get('mail', '').strip()
    password = request.form.get('password', '').strip()
    group_name = request.form.get('group', 'sinhvien').strip()

    if not uid or not cn or not password:
        flash('Vui lòng nhập đầy đủ Username, Họ tên và Mật khẩu.', 'warning')
        return redirect(url_for('users_list'))

    try:
        ldap_client.create_user(uid, cn, sn, mail, password, group_name)
        DBManager.add_audit_log(
            actor=session.get('username'),
            action="CREATE_USER",
            target=uid,
            new_value=f"Group: {group_name}, Name: {cn}",
            ip=request.remote_addr
        )
        flash(f'Đã thêm thành công người dùng {uid} vào nhóm {group_name}.', 'success')
    except Exception as e:
        flash(f'Lỗi khi thêm người dùng: {e}', 'danger')

    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
    return redirect(url_for('users_list', sid=current_sid))

@app.route('/users/delete/<uid>', methods=['POST'])
@login_required
@admin_required
def user_delete(uid):
    try:
        ldap_client.delete_user(uid)
        DBManager.add_audit_log(
            actor=session.get('username'),
            action="DELETE_USER",
            target=uid,
            ip=request.remote_addr
        )
        flash(f'Đã xóa tài khoản {uid} khỏi LDAP thành công.', 'success')
    except Exception as e:
        flash(f'Lỗi khi xóa người dùng: {e}', 'danger')
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
    return redirect(url_for('users_list', sid=current_sid))

@app.route('/users/quarantine/<uid>', methods=['POST'])
@login_required
@admin_required
def user_quarantine(uid):
    try:
        old_group = ldap_client.get_user_group(uid)
        ldap_client.quarantine_user(uid)
        DBManager.add_audit_log(
            actor=session.get('username'),
            action="MANUAL_QUARANTINE",
            target=uid,
            old_val=f"Group: {old_group}",
            new_val="Group: quarantine (VLAN 99)",
            ip=request.remote_addr
        )
        flash(f'Đã đưa người dùng {uid} vào diện cách ly (VLAN 99).', 'warning')
    except Exception as e:
        flash(f'Lỗi khi cách ly người dùng: {e}', 'danger')
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
    return redirect(url_for('users_list', sid=current_sid))

@app.route('/users/unlock/<uid>', methods=['POST'])
@login_required
@admin_required
def user_unlock(uid):
    target_group = request.form.get('target_group', 'sinhvien')
    try:
        ldap_client.unquarantine_user(uid, target_group)
        # 1. Xóa alert của tài khoản này khỏi recent_alerts
        detector_instance.recent_alerts = [a for a in detector_instance.recent_alerts if a.get('username') != uid]
        
        # 2. Đánh dấu các reject cũ trong radpostauth để tránh bị quarantine lại ngay lập tức
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE radpostauth 
                    SET reply = 'Access-Reject-Resolved' 
                    WHERE username = %s AND reply = 'Access-Reject'
                """, (uid,))
        except Exception:
            pass
        finally:
            conn.close()

        DBManager.add_audit_log(
            actor=session.get('username'),
            action="UNLOCK_USER",
            target=uid,
            old_val="Group: quarantine",
            new_val=f"Group: {target_group}",
            ip=request.remote_addr
        )
        flash(f'Đã mở khóa tài khoản {uid} và khôi phục về nhóm {target_group}.', 'success')
    except Exception as e:
        flash(f'Lỗi khi mở khóa: {e}', 'danger')
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
    return redirect(url_for('users_list', sid=current_sid))

@app.route('/api/live-status')
@login_required
def api_live_status():
    """API giám sát các cuộc tấn công Brute-force và cập nhật trạng thái hệ thống theo thời gian thực."""
    try:
        attacks = detector_instance.get_live_attacks()
        alerts = detector_instance.recent_alerts
        
        # Đếm số lượng Access-Reject hôm nay
        today_rejects = 0
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) as count FROM radpostauth WHERE (reply = 'Access-Reject' OR reply = 'Access-Reject-Resolved') AND DATE(authdate) = CURDATE()")
                row = cursor.fetchone()
                if row:
                    today_rejects = row['count']
        except Exception:
            pass
        finally:
            conn.close()

        # Lấy danh sách người dùng và nhóm hiện tại từ LDAP
        users = ldap_client.get_all_users()
        quarantined_count = sum(1 for u in users if u.get('group') == 'quarantine' or u.get('status') == 'quarantined')
        active_count = len(users) - quarantined_count

        return jsonify({
            'status': 'success',
            'attacks': attacks,
            'alerts': alerts,
            'today_rejects': today_rejects,
            'quarantined_count': quarantined_count,
            'active_count': active_count,
            'total_users': len(users),
            'users': [{'uid': u['uid'], 'group': u['group'], 'vlan': u['vlan'], 'status': u['status']} for u in users]
        })
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/policies')
@login_required
def policies_list():
    policies = DBManager.get_policies()
    return render_template('policies.html', policies=policies)

@app.route('/policies/update', methods=['POST'])
@login_required
@admin_required
def policy_update():
    group_name = request.form.get('group_name')
    vlan_id = int(request.form.get('vlan_id'))
    vlan_name = request.form.get('vlan_name')
    session_timeout = int(request.form.get('session_timeout', 14400))
    idle_timeout = int(request.form.get('idle_timeout', 600))

    try:
        DBManager.update_policy(group_name, vlan_id, vlan_name, session_timeout, idle_timeout)
        DBManager.add_audit_log(
            actor=session.get('username'),
            action="UPDATE_POLICY",
            target=group_name,
            new_value=f"VLAN {vlan_id} ({vlan_name}), Timeout: {session_timeout}s",
            ip=request.remote_addr
        )
        flash(f'Đã cập nhật chính sách cho nhóm {group_name} thành VLAN {vlan_id}. Có hiệu lực ngay lập tức!', 'success')
    except Exception as e:
        flash(f'Lỗi khi cập nhật chính sách: {e}', 'danger')

    return redirect(url_for('policies_list'))

@app.route('/logs')
@login_required
def logs_view():
    search_user = request.args.get('user', '').strip()
    logs = DBManager.get_auth_logs(limit=150, username=search_user if search_user else None)
    return render_template('logs.html', logs=logs, search_user=search_user)

@app.route('/sessions')
@login_required
def sessions_view():
    sessions = DBManager.get_active_sessions()
    return render_template('sessions.html', sessions=sessions)

@app.route('/audit')
@login_required
def audit_view():
    audit_logs = DBManager.get_audit_logs(limit=150)
    return render_template('audit.html', audit_logs=audit_logs)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
