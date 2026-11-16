import os
import secrets
import urllib.parse
import time
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify, abort, g, make_response
from flask.sessions import SessionInterface, SessionMixin
from config import Config
from ldap_client import LDAPClient
from models import DBManager, get_db_connection
from detector import detector_instance
from mfa import generate_secret, get_totp_code, verify_totp, verify_totp_detailed, get_totp_uri
from sso import (
    create_jwt, verify_jwt, get_jwks,
    create_access_token, create_id_token,
    verify_pkce, hash_client_secret, verify_client_secret
)
from mailer import send_password_reset_email
import hmac
import re

from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.config.from_object(Config)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

def is_safe_redirect_url(target):
    """
    Kiểm tra URL chuyển hướng an toàn, ngăn chặn triệt để tấn công Open Redirect (CWE-601).
    Từ chối tuyệt đối protocol-relative URLs (//evil.com), backslash evasion (/\evil.com, \evil.com),
    và các URL có scheme hoặc netloc khác rỗng.
    """
    if not target or not isinstance(target, str):
        return False
    if target.startswith('//') or target.startswith('/\\') or target.startswith('\\'):
        return False
    parsed = urllib.parse.urlparse(target)
    if parsed.netloc != '' or parsed.scheme != '':
        return False
    if not target.startswith('/'):
        return False
    if target.startswith('/login'):
        return False
    return True

def validate_password_policy(password: str) -> tuple:
    """
    Xác thực Chính sách Mật khẩu mạnh:
    1. Độ dài tối thiểu 12 ký tự.
    2. Có ít nhất một chữ cái in hoa (A-Z).
    3. Mật khẩu phải có cả chữ cái thường (a-z) và chữ số (0-9).
    4. Có ít nhất một ký tự đặc biệt (!@#$%^&*()_+-=[]{}|;:,.<>?/~`"'\).
    """
    if not password or not isinstance(password, str):
        return False, "Mật khẩu không được để trống."

    missing = []
    if len(password) < 12:
        missing.append(f"Tối thiểu 12 ký tự (hiện có: {len(password)})")
    if not re.search(r'[A-Z]', password):
        missing.append("Ít nhất 1 chữ cái in hoa (A-Z)")
    if not re.search(r'[a-z]', password):
        missing.append("Ít nhất 1 chữ cái in thường (a-z)")
    if not re.search(r'[0-9]', password):
        missing.append("Ít nhất 1 chữ số (0-9)")
    if not re.search(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?/~`"\'\\]', password):
        missing.append("Ít nhất 1 ký tự đặc biệt (!@#$%^&*...)")

    if missing:
        err_msg = "Mật khẩu chưa đạt chuẩn bảo mật: " + "; ".join(missing) + "."
        return False, err_msg

    return True, ""

# ====================================================================
# MULTI-TAB SESSION ISOLATION (HỖ TRỢ ĐĂNG NHẬP NHIỀU USER TRÊN CÁC TAB KHÁC NHAU)
# ====================================================================
class TabSession(dict, SessionMixin):
    def __init__(self, sid, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sid = sid
        self.modified = False

class TabSessionInterface(SessionInterface):
    """Lưu trữ session kết hợp Tab Session ID (sid) và Cookie dự phòng."""
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
        if not sid:
            # Fallback sang Cookie nac_session_sid
            sid = request.cookies.get('nac_session_sid')
        if sid and isinstance(sid, str):
            sid = sid.split('?')[0].split('&')[0].strip()
        return sid

    def open_session(self, app, request):
        sid = self._extract_sid(request)
        if not sid:
            sid = secrets.token_hex(6)
            s = TabSession(sid)
            self.store[sid] = s
            return s
        if sid not in self.store:
            s = TabSession(sid)
            # Khôi phục phiên từ MariaDB sso_sessions nếu server/container vừa restart
            try:
                master_rec = DBManager.get_sso_master_session(sid)
                if master_rec and master_rec.get('username'):
                    u = master_rec['username']
                    s['logged_in'] = True
                    s['username'] = u
                    if u in ADMIN_USERS:
                        s['role'] = ADMIN_USERS[u]['role']
                        s['display_name'] = ADMIN_USERS[u]['name']
                        s['group'] = 'quantri'
                        s['vlan'] = '10'
                        s['email'] = f"{u}@ptit.edu.vn"
                    else:
                        s['role'] = 'user'
                        try:
                            import ldap_client
                            u_info = ldap_client.get_user_info(u)
                        except Exception:
                            u_info = None
                        if u_info:
                            s['display_name'] = u_info.get('cn') or u
                            s['group'] = u_info.get('group', 'sinhvien')
                            s['vlan'] = u_info.get('vlan', '20')
                            s['email'] = u_info.get('mail', f"{u}@ptit.edu.vn")
                        else:
                            s['display_name'] = u
                            s['group'] = 'sinhvien'
                            s['vlan'] = '20'
                            s['email'] = f"{u}@ptit.edu.vn"
            except Exception:
                pass
            self.store[sid] = s
        return self.store[sid]

    def save_session(self, app, session, response):
        if hasattr(session, 'sid'):
            self.store[session.sid] = session
            if session.get('logged_in'):
                response.set_cookie(
                    'nac_session_sid',
                    session.sid,
                    path='/',
                    httponly=True,
                    samesite='Lax'
                )

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

    if not sid:
        cookie_sid = request.cookies.get('nac_session_sid')
        if cookie_sid:
            sid = cookie_sid

    if sid and isinstance(sid, str):
        sid = sid.split('?')[0].split('&')[0].strip()

    if not sid:
        # Không có sid và không có cookie -> tạo sid mới
        if request.method == 'GET':
            new_sid = secrets.token_hex(6)
            args = request.args.to_dict()
            args['sid'] = new_sid
            query_str = urllib.parse.urlencode(args)
            return redirect(f"{request.path}?{query_str}")
        else:
            g.sid = getattr(session, 'sid', None) or secrets.token_hex(6)
            return

    # Nếu request GET không có sid trên URL nhưng đã có sid từ cookie, redirect nhẹ kèm ?sid=
    if request.method == 'GET' and 'sid' not in request.args:
        args = request.args.to_dict()
        args['sid'] = sid
        query_str = urllib.parse.urlencode(args)
        return redirect(f"{request.path}?{query_str}")

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
    'admin': {'password': 'AdminPassword123!', 'role': 'admin', 'name': 'Quản Trị Viên Toàn Quyền', 'group': 'quantri', 'vlan': 10},
    'auditor': {'password': 'AuditorPass123!', 'role': 'auditor', 'name': 'Cán Bộ Kiểm Toán An Toàn', 'group': 'giangvien', 'vlan': 30}
}

def resolve_user_group(username: str) -> str:
    """Xác định nhóm người dùng nhất quán giữa ADMIN_USERS và LDAP."""
    if not username:
        return "sinhvien"
    if username in ADMIN_USERS:
        return ADMIN_USERS[username].get('group', 'quantri')
    return ldap_client.get_user_group(username) or "sinhvien"

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
        role = session.get('role')
        if role != 'admin':
            if request.is_json or request.method in ['POST', 'PUT', 'DELETE']:
                abort(403)
            if role == 'user':
                flash('Từ chối quyền truy cập! Trang này chỉ dành cho Quản trị viên hệ thống.', 'danger')
                return redirect(url_for('sso_portal'))
            flash('Từ chối quyền truy cập! Vai trò Kiểm toán (Auditor) chỉ được xem, không được chỉnh sửa.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

def staff_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') not in ['admin', 'auditor']:
            flash('Từ chối quyền truy cập! Trang quản trị này chỉ dành cho Quản trị viên và Kiểm toán viên hệ thống.', 'warning')
            return redirect(url_for('sso_portal'))
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

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Tự đăng ký tài khoản người dùng mới (Self-Registration) trực tuyến."""
    if session.get('logged_in'):
        if session.get('role') == 'user':
            return redirect(url_for('sso_portal'))
        return redirect(url_for('index'))

    client_ip = request.remote_addr or '127.0.0.1'

    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or ''

    # 1. Kiểm tra xem Địa chỉ IP có đang bị tạm chặn hay không
    ip_lock = DBManager.check_dashboard_ip_lock(client_ip)
    if ip_lock['is_blocked']:
        target_user = ip_lock.get('last_target_user') or "tài khoản vi phạm"
        flash(f'Địa chỉ IP của bạn ({client_ip}) đang bị tạm chặn do liên quan đến {target_user}. Không thể đăng ký tài khoản mới.', 'danger')
        return redirect(url_for('login', sid=current_sid))

    if request.method == 'POST':
        uid = request.form.get('uid', '').strip().lower()
        cn = request.form.get('cn', '').strip()
        mail = request.form.get('mail', '').strip()
        group = request.form.get('group', 'sinhvien').strip()
        password = request.form.get('password', '').strip()
        confirm_password = request.form.get('confirm_password', '').strip()

        # 1. Kiểm tra trường bắt buộc
        if not uid or not cn or not mail or not password:
            flash('Vui lòng điền đầy đủ tất cả các trường thông tin bắt buộc.', 'warning')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 2. Kiểm tra định dạng UID (chữ thường, số, gạch dưới, 3-30 ký tự)
        if not re.match(r'^[a-z0-9_]{3,30}$', uid):
            flash('Tên đăng nhập không hợp lệ. Chỉ chấp nhận chữ cái thường, số và dấu gạch dưới (3 - 30 ký tự).', 'warning')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 3. Chặn các định danh đặc quyền / hệ thống
        RESERVED_USERNAMES = {'admin', 'auditor', 'root', 'administrator', 'system', 'radius', 'guest', 'quarantine', 'quantri'}
        if uid in RESERVED_USERNAMES or uid in ADMIN_USERS:
            flash(f'Tên đăng nhập "{uid}" là định danh quản trị/hệ thống dành riêng. Vui lòng chọn tên khác.', 'danger')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 4. Kiểm tra nhóm được phép tự đăng ký (chỉ sinhvien hoặc giangvien)
        ALLOWED_GROUPS = {'sinhvien', 'giangvien'}
        if group not in ALLOWED_GROUPS:
            flash('Nhóm người dùng không hợp lệ. Chỉ được phép đăng ký nhóm Sinh viên hoặc Giảng viên.', 'danger')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group='sinhvien', sid=current_sid)

        # 5. Kiểm tra chính sách mật khẩu mạnh (Tối thiểu 12 ký tự, hoa, thường, số, ký tự đặc biệt)
        is_valid_pw, pw_err = validate_password_policy(password)
        if not is_valid_pw:
            flash(pw_err, 'warning')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        if password != confirm_password:
            flash('Mật khẩu xác nhận không khớp với mật khẩu đã nhập.', 'warning')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 6. Kiểm tra email
        if '@' not in mail or '.' not in mail:
            flash('Địa chỉ email không đúng định dạng.', 'warning')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 7. Kiểm tra trùng lặp tài khoản trên OpenLDAP
        try:
            if ldap_client.user_exists(uid):
                flash(f'Tên đăng nhập "{uid}" đã tồn tại trong hệ thống. Vui lòng chọn tên đăng nhập khác.', 'warning')
                return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)
        except Exception as e:
            flash(f'Lỗi kết nối máy chủ xác thực OpenLDAP: {e}', 'danger')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

        # 8. Tạo tài khoản trên OpenLDAP & ghi log kiểm toán
        try:
            sn = cn.split()[-1] if cn.split() else 'User'
            vlan_id = '20' if group == 'sinhvien' else '30'
            desc = f"Tự đăng ký trực tuyến - Nhóm {group} (VLAN {vlan_id})"
            ldap_client.create_user(uid=uid, cn=cn, sn=sn, mail=mail, password=password, group_name=group, desc=desc)

            DBManager.add_audit_log(
                actor=uid,
                action="SELF_REGISTER",
                target="OPENLDAP",
                old_val="NEW_USER_REGISTRATION",
                new_val=f"Group: {group} (VLAN {vlan_id}), Name: {cn}, Email: {mail}",
                ip=client_ip
            )

            flash(f'Chúc mừng bạn đã đăng ký tài khoản "{uid}" thành công! Vui lòng đăng nhập để bắt đầu sử dụng Cổng SSO.', 'success')
            return redirect(url_for('login', sid=current_sid))
        except Exception as e:
            flash(f'Lỗi khi tạo tài khoản trên OpenLDAP: {e}', 'danger')
            return render_template('register.html', uid=uid, cn=cn, mail=mail, group=group, sid=current_sid)

    return render_template('register.html', group='sinhvien', sid=current_sid)

# Hộp thư gửi ra mô phỏng (hỗ trợ hiển thị trên PTIT Webmail và kiểm thử tự động)
SIMULATED_OUTBOX = []

@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    """Yêu cầu khôi phục mật khẩu qua Email (Self-Service Password Reset)."""
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or ''
    client_ip = request.remote_addr or '127.0.0.1'

    # 1. Kiểm tra xem Địa chỉ IP có đang bị tạm chặn hay không
    ip_lock = DBManager.check_dashboard_ip_lock(client_ip)
    if ip_lock['is_blocked']:
        target_user = ip_lock.get('last_target_user') or "tài khoản vi phạm"
        flash(f'Địa chỉ IP của bạn ({client_ip}) đang bị tạm chặn do liên quan đến {target_user}. Vui lòng thử lại sau {ip_lock["minutes_left"]} phút!', 'danger')
        return redirect(url_for('login', sid=current_sid))

    if request.method == 'POST':
        identifier = request.form.get('identifier', '').strip()
        if not identifier:
            flash('Vui lòng nhập Tên đăng nhập hoặc Email trường @ptit.edu.vn.', 'warning')
            return render_template('forgot_password.html', sid=current_sid)

        # 2. Tra cứu người dùng trong OpenLDAP
        user_info = ldap_client.get_user_by_email_or_uid(identifier)

        # Chống User Enumeration: Nếu không tìm thấy, vẫn báo thành công chung chung để bảo mật
        if not user_info:
            flash('Nếu tài khoản tồn tại trong hệ thống, hướng dẫn khôi phục mật khẩu đã được gửi đến email đăng ký của bạn.', 'info')
            return render_template('forgot_password.html', sid=current_sid, email_sent=True, target_email=identifier)

        username = user_info['uid']
        email = user_info.get('mail') or f"{username}@ptit.edu.vn"

        # 3. Sinh mã Token One-Time bảo mật (32 bytes urlsafe)
        raw_token = secrets.token_urlsafe(32)

        # 4. Lưu băm SHA-256 vào MariaDB (thời hạn 15 phút)
        DBManager.create_password_reset_token(
            username=username,
            email=email,
            raw_token=raw_token,
            expires_minutes=15,
            ip_address=client_ip
        )

        # 5. Tạo đường dẫn liên kết xác thực khôi phục mật khẩu
        reset_link = url_for('reset_password', token=raw_token, sid=current_sid, _external=True)

        # 6. Gửi Email THỰC TẾ qua SMTP (nếu được cấu hình trong .env)
        sent_real, mail_msg = send_password_reset_email(
            to_email=email,
            username=username,
            reset_link=reset_link,
            expires_minutes=15
        )

        # 7. Đồng thời lưu vào Hộp thư mô phỏng (cho PTIT Webmail và kịch bản demo lab)
        email_record = {
            'to': email,
            'username': username,
            'subject': '[PTIT IT Security] Yêu cầu đặt lại mật khẩu tài khoản mạng & SSO',
            'reset_link': reset_link,
            'token': raw_token,
            'sent_at': time.strftime('%H:%M:%S %d/%m/%Y'),
            'expires_in': '15 phút',
            'is_real_smtp': sent_real
        }
        SIMULATED_OUTBOX.append(email_record)

        # 8. Ghi nhận vào nhật ký kiểm toán Audit Log (chống chối bỏ)
        DBManager.add_audit_log(
            actor=client_ip,
            action="PASSWORD_RESET_REQUESTED",
            target=username,
            old_val="",
            new_val=f"Tạo liên kết đổi mật khẩu gửi tới {email} (Real SMTP: {sent_real}, TTL: 15m)",
            ip=client_ip
        )

        if sent_real:
            flash(f'Thư xác thực khôi phục mật khẩu đã được gửi đến hộp thư Email thật của bạn ({email})! Vui lòng kiểm tra Hộp thư đến (hoặc thư mục Spam/Quảng cáo).', 'success')
        else:
            flash(f'Liên kết đặt lại mật khẩu đã được tạo thành công cho {email}! (Chế độ mô phỏng Lab)', 'success')

        return render_template('forgot_password.html', sid=current_sid, email_sent=True, target_email=email, demo_reset_link=reset_link, is_real_smtp=sent_real)

    return render_template('forgot_password.html', sid=current_sid, email_sent=False)


@app.route('/reset-password', methods=['GET', 'POST'])
def reset_password():
    """Xác thực token nhận từ Email và cho phép đặt lại mật khẩu mới trên OpenLDAP."""
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or ''
    client_ip = request.remote_addr or '127.0.0.1'

    raw_token = request.args.get('token') or request.form.get('token', '').strip()
    if not raw_token:
        flash('Mã xác thực token không hợp lệ hoặc bị thiếu.', 'danger')
        return redirect(url_for('forgot_password', sid=current_sid))

    # 1. Xác thực tính hợp lệ của Token
    token_status = DBManager.verify_password_reset_token(raw_token)
    if not token_status or not token_status.get('valid'):
        reason = token_status.get('reason') if token_status else 'invalid'
        if reason == 'used':
            flash('Liên kết khôi phục này đã được sử dụng trước đó (Anti-Replay Protection). Vui lòng gửi yêu cầu mới.', 'warning')
        elif reason == 'expired':
            flash('Liên kết khôi phục đã hết hạn (quá 15 phút). Vui lòng gửi yêu cầu mới.', 'warning')
        else:
            flash('Mã xác thực token không hợp lệ hoặc không tồn tại trong hệ thống.', 'danger')
        return redirect(url_for('forgot_password', sid=current_sid))

    username = token_status['username']
    email = token_status['email']
    token_id = token_status['token_id']

    if request.method == 'POST':
        new_password = request.form.get('new_password', '').strip()
        confirm_password = request.form.get('confirm_password', '').strip()

        if not new_password or not confirm_password:
            flash('Vui lòng nhập đầy đủ mật khẩu mới và xác nhận mật khẩu.', 'warning')
            return render_template('reset_password.html', token=raw_token, username=username, email=email, sid=current_sid)

        if new_password != confirm_password:
            flash('Mật khẩu xác nhận không khớp với mật khẩu mới.', 'danger')
            return render_template('reset_password.html', token=raw_token, username=username, email=email, sid=current_sid)

        # 2. Kiểm tra Chính sách mật khẩu mạnh
        is_strong, err_msg = validate_password_policy(new_password)
        if not is_strong:
            flash(err_msg, 'danger')
            return render_template('reset_password.html', token=raw_token, username=username, email=email, sid=current_sid)

        # 3. Cập nhật mật khẩu mới trên OpenLDAP (mã hóa Salted SSHA)
        success = ldap_client.reset_user_password(username, new_password)
        if not success:
            flash('Không thể cập nhật mật khẩu mới trên OpenLDAP. Vui lòng liên hệ Quản trị viên.', 'danger')
            return render_template('reset_password.html', token=raw_token, username=username, email=email, sid=current_sid)

        # 4. Đánh dấu Token đã sử dụng xong (ngăn chặn tấn công dùng lại - Replay Attack)
        DBManager.mark_password_reset_token_used(token_id)

        # 5. Ghi nhận sự kiện đổi mật khẩu thành công vào Audit Log
        DBManager.add_audit_log(
            actor=username,
            action="PASSWORD_RESET_SUCCESS",
            target=username,
            old_val="",
            new_val=f"Đặt lại mật khẩu thành công qua email xác thực {email}",
            ip=client_ip
        )

        flash('Chúc mừng! Bạn đã đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới.', 'success')
        return redirect(url_for('login', sid=current_sid))

    return render_template('reset_password.html', token=raw_token, username=username, email=email, sid=current_sid)

@app.route('/login', methods=['GET', 'POST'])
def login():
    client_ip = request.remote_addr or '127.0.0.1'

    # 1. Kiểm tra xem Địa chỉ IP có đang bị tạm chặn hay không
    ip_lock = DBManager.check_dashboard_ip_lock(client_ip)
    if ip_lock['is_blocked']:
        target_user = ip_lock.get('last_target_user') or "tài khoản vi phạm"
        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '').strip()
            # Đặc quyền cứu hộ hệ thống: Admin có thể đăng nhập kể cả khi IP bị chặn nếu nhập đúng pass admin
            if username in ADMIN_USERS and ADMIN_USERS[username]['password'] == password and ADMIN_USERS[username]['role'] == 'admin':
                pass # Bỏ qua chặn IP cho Quản trị viên cứu hộ
            else:
                DBManager.add_audit_log(
                    actor=client_ip,
                    action="DASHBOARD_IP_BLOCKED",
                    target="DASHBOARD",
                    old_val=f"Attempted username: {username}",
                    new_val=f"IP đang bị chặn liên quan đến {target_user}. Còn {ip_lock['minutes_left']} phút.",
                    ip=client_ip
                )
                flash(f'Địa chỉ IP của bạn ({client_ip}) đang bị chặn do liên quan đến tài khoản vi phạm bị cách ly ({target_user}). Vui lòng thử lại sau {ip_lock["minutes_left"]} phút!', 'danger')
                return render_template('login.html', is_ip_blocked=True, lock_minutes=ip_lock['minutes_left'], blocked_target_user=target_user)
        else:
            flash(f'Địa chỉ IP của bạn ({client_ip}) đang bị tạm chặn do liên quan đến {target_user}.', 'danger')
            return render_template('login.html', is_ip_blocked=True, lock_minutes=ip_lock['minutes_left'], blocked_target_user=target_user)

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()

        # Kiểm tra xem Tài khoản username có tồn tại trong hệ thống (ADMIN_USERS hoặc OpenLDAP) hay không
        is_admin_user = username in ADMIN_USERS
        is_ldap_user = False
        ldap_info = None

        if not is_admin_user:
            try:
                if ldap_client.user_exists(username):
                    is_ldap_user = True
                    ldap_info = ldap_client.get_user_info(username)
            except Exception:
                is_ldap_user = False

        user_exists = is_admin_user or is_ldap_user

        # 2. Kiểm tra xem Tài khoản username có đang bị tạm khóa hay không (chỉ kiểm tra nếu tài khoản tồn tại)
        if user_exists:
            acc_lock = DBManager.check_dashboard_account_lock(username)
            if acc_lock['is_locked']:
                DBManager.add_audit_log(
                    actor=username,
                    action="DASHBOARD_ACCOUNT_BLOCKED",
                    target="DASHBOARD",
                    old_val=f"IP: {client_ip}",
                    new_val=f"Tài khoản đang bị khóa. Còn {acc_lock['minutes_left']} phút.",
                    ip=client_ip
                )
                flash(f'Tài khoản {username} đang bị tạm khóa. Vui lòng thử lại sau {acc_lock["minutes_left"]} phút!', 'danger')
                return render_template('login.html', is_account_locked=True, lock_minutes=acc_lock['minutes_left'])

        # 3. Kiểm tra thông tin xác thực
        auth_success = False
        user_role = 'user'
        user_display_name = username
        user_group = 'sinhvien'
        user_vlan = '20'
        user_email = f"{username}@ptit.edu.vn"

        if is_admin_user:
            if ADMIN_USERS[username]['password'] == password:
                auth_success = True
                user_role = ADMIN_USERS[username]['role']
                user_display_name = ADMIN_USERS[username]['name']
                user_group = 'quantri'
                user_vlan = '10'
                user_email = f"{username}@ptit.edu.vn"
        elif is_ldap_user:
            if ldap_client.authenticate(username, password):
                auth_success = True
                user_role = 'user'
                if ldap_info:
                    user_display_name = ldap_info.get('cn') or username
                    user_group = ldap_info.get('group', 'sinhvien')
                    user_vlan = ldap_info.get('vlan', '20')
                    user_email = ldap_info.get('mail', f"{username}@ptit.edu.vn")

        if auth_success:
            # Đăng nhập hợp lệ -> Giải phóng số lần sai của IP và tài khoản
            DBManager.record_dashboard_login_success(username, client_ip)

            # Kiểm tra trạng thái Xác thực đa nhân tố (MFA / 2FA)
            mfa_record = DBManager.get_user_mfa(username)
            if mfa_record and mfa_record.get('is_enabled') == 1:
                lock_info = DBManager.check_mfa_lock(username)
                if lock_info['is_locked']:
                    flash(f'Tài khoản {username} đang bị tạm khóa xác thực MFA do nhập sai quá 3 lần. Vui lòng thử lại sau {lock_info["minutes_left"]} phút!', 'danger')
                    return redirect(url_for('login'))

                session['mfa_pending'] = True
                session['mfa_username'] = username
                session['mfa_role'] = user_role
                session['mfa_name'] = user_display_name
                session['mfa_group'] = user_group
                session['mfa_vlan'] = user_vlan
                session['mfa_email'] = user_email
                session['mfa_next'] = request.args.get('next', '')
                flash('Mật khẩu hợp lệ! Vui lòng nhập mã xác thực OTP 6 số từ ứng dụng Authenticator (MFA Step 2).', 'info')
                return redirect(url_for('mfa_verify'))

            # Đăng nhập trực tiếp nếu chưa bật MFA
            session['logged_in'] = True
            session['username'] = username
            session['role'] = user_role
            session['display_name'] = user_display_name
            session['group'] = user_group
            session['vlan'] = user_vlan
            session['email'] = user_email
            
            # Ghi nhận Master Session cho SSO & Single Logout (SLO)
            DBManager.record_sso_master_session(session.sid, username, client_ip, request.user_agent.string)
            
            DBManager.add_audit_log(
                actor=username,
                action="DASHBOARD_LOGIN",
                target="SYSTEM",
                new_value=f"Login success as {session['role']} ({user_group})",
                ip=client_ip
            )
            flash(f'Chào mừng {session["display_name"]} đăng nhập thành công!', 'success')
            next_url = request.args.get('next')
            if next_url and is_safe_redirect_url(next_url):
                return redirect(next_url)
            if session['role'] == 'user':
                return redirect(url_for('sso_portal'))
            return redirect(url_for('index'))
        else:
            # Nhập sai: Phân biệt tài khoản có tồn tại và tài khoản không tồn tại
            if user_exists:
                # Tài khoản TỒN TẠI: Ghi nhận số lần sai cho tài khoản và IP kèm cảnh báo đếm ngược
                fail_info = DBManager.record_dashboard_login_failure(username, client_ip, max_attempts=5, lock_minutes=60)
                if fail_info['is_locked']:
                    # Lần thứ 5: Khóa cả Tài khoản và Địa chỉ IP trong 1 tiếng (60 phút)
                    DBManager.add_audit_log(
                        actor=username,
                        action="DASHBOARD_ACCOUNT_LOCKED",
                        target="DASHBOARD",
                        old_value=f"Nhập sai {fail_info['failed_attempts']} lần liên tiếp từ IP {client_ip}",
                        new_value=f"Khóa tài khoản {username} trong 60 phút",
                        ip=client_ip
                    )
                    DBManager.add_audit_log(
                        actor=client_ip,
                        action="DASHBOARD_IP_BLOCKED",
                        target="DASHBOARD",
                        old_value=f"Thử dò tài khoản: {username}",
                        new_value=f"Chặn địa chỉ IP {client_ip} trong 60 phút",
                        ip=client_ip
                    )
                    flash('Bạn đã nhập sai mật khẩu quá 5 lần! Tài khoản và địa chỉ IP của bạn đã bị khóa trong 1 tiếng.', 'danger')
                else:
                    rem = fail_info['remaining_attempts']
                    DBManager.add_audit_log(
                        actor=username,
                        action="DASHBOARD_LOGIN_FAILED",
                        target="DASHBOARD",
                        old_value=f"Lần sai thứ {fail_info['failed_attempts']}/5",
                        new_value=f"Còn {rem} lần thử trước khi bị khóa",
                        ip=client_ip
                    )
                    flash(f'Sai tên đăng nhập hoặc mật khẩu! Bạn còn {rem} lần thử trước khi tài khoản bị khóa.', 'danger')
            else:
                # Tài khoản KHÔNG TỒN TẠI:
                # Tuyệt đối không tạo bản ghi khóa cho tài khoản ảo, chỉ ghi nhận thất bại cho IP
                ip_fail_info = DBManager.record_dashboard_ip_failure(client_ip, target_user=username or "UNKNOWN", max_attempts=5, lock_minutes=60)
                if ip_fail_info['is_blocked']:
                    DBManager.add_audit_log(
                        actor=client_ip,
                        action="DASHBOARD_IP_BLOCKED",
                        target="DASHBOARD",
                        old_value=f"Dò quét username không tồn tại ({username}) 5 lần liên tiếp",
                        new_value=f"Chặn địa chỉ IP {client_ip} trong 60 phút",
                        ip=client_ip
                    )
                    flash('Địa chỉ IP của bạn đã bị tạm khóa 1 tiếng do nhập sai quá 5 lần!', 'danger')
                else:
                    DBManager.add_audit_log(
                        actor="UNKNOWN",
                        action="DASHBOARD_LOGIN_FAILED",
                        target="DASHBOARD",
                        old_value=f"Username không tồn tại: {username}",
                        new_value=f"IP {client_ip} thử sai {ip_fail_info['failed_attempts']}/5",
                        ip=client_ip
                    )
                    flash('Sai tên đăng nhập hoặc mật khẩu!', 'danger')

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
            role = session.get('mfa_role', 'user')
            display_name = session.get('mfa_name', username)
            group = session.get('mfa_group', 'sinhvien')
            vlan = session.get('mfa_vlan', '20')
            email = session.get('mfa_email', f"{username}@ptit.edu.vn")
            next_url = session.get('mfa_next')

            session.pop('mfa_pending', None)
            session.pop('mfa_username', None)
            session.pop('mfa_role', None)
            session.pop('mfa_name', None)
            session.pop('mfa_group', None)
            session.pop('mfa_vlan', None)
            session.pop('mfa_email', None)
            session.pop('mfa_next', None)

            session['logged_in'] = True
            session['username'] = username
            session['role'] = role
            session['display_name'] = display_name
            session['group'] = group
            session['vlan'] = vlan
            session['email'] = email
            
            # Ghi nhận Master Session cho SSO & Single Logout (SLO)
            DBManager.record_sso_master_session(session.sid, username, request.remote_addr, request.user_agent.string)
            
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
            if next_url and is_safe_redirect_url(next_url):
                return redirect(next_url)
            if role == 'user':
                return redirect(url_for('sso_portal'))
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
@app.route('/sso')
@app.route('/sso/portal')
def sso_portal():
    """Cổng khởi động SSO tập trung (Unified SSO Launchpad)."""
    clients = DBManager.get_sso_clients()
    is_authenticated = session.get('logged_in', False)
    current_username = session.get('username', '')
    current_role = session.get('role', '')
    display_name = session.get('display_name', current_username)
    
    if current_role == 'user':
        clients = [c for c in clients if c['client_id'] != 'nac_admin']
    
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

    is_quarantined = (user_group == 'quarantine' or user_vlan == '99')
    active_apps = []
    if is_authenticated and hasattr(session, 'sid') and not is_quarantined:
        active_apps = DBManager.get_active_sso_client_apps(session.sid)

    return render_template('sso_portal.html', 
                           clients=clients, 
                           active_apps=active_apps,
                           is_authenticated=is_authenticated,
                           username=current_username,
                           display_name=display_name,
                           role=current_role,
                           user_group=user_group,
                           user_vlan=user_vlan,
                           is_quarantined=is_quarantined)

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
        "end_session_endpoint": f"{base_url}/oauth/logout",
        "response_types_supported": ["code", "token", "id_token"],
        "subject_types_supported": ["public"],
        "id_token_signing_alg_values_supported": ["RS256"],
        "code_challenge_methods_supported": ["S256", "plain"],
        "scopes_supported": ["openid", "profile", "email", "groups", "vlan"],
        "token_endpoint_auth_methods_supported": ["client_secret_post", "client_secret_basic"],
        "claims_supported": ["sub", "iss", "aud", "exp", "iat", "auth_time", "nonce", "name", "email", "group", "vlan", "at_hash"]
    })

@app.route('/oauth/jwks')
def oauth_jwks():
    """JSON Web Key Set (RFC 7517). Cho phép client tải khóa công khai RSA để tự xác minh chữ ký RS256."""
    return jsonify(get_jwks())

@app.route('/oauth/authorize', methods=['GET', 'POST'])
def oauth_authorize():
    """OAuth 2.0 Authorization Endpoint (Authorization Code Flow kèm PKCE & Nonce)."""
    client_id = request.args.get('client_id')
    redirect_uri = request.args.get('redirect_uri')
    state = request.args.get('state', '')
    nonce = request.args.get('nonce')
    code_challenge = request.args.get('code_challenge')
    code_challenge_method = request.args.get('code_challenge_method')
    
    client = DBManager.get_sso_client(client_id)
    if not client:
        return jsonify({"error": "invalid_client", "error_description": "Client ID not registered in SSO directory"}), 400

    # Khắc phục lỗ hổng redirect_uri:
    # Nếu client truyền redirect_uri, PHẢI so khớp chính xác với URI đã đăng ký của client
    registered_uris = [u.strip() for u in client['redirect_uri'].split(',') if u.strip()]
    if redirect_uri:
        if redirect_uri not in registered_uris:
            return jsonify({
                "error": "invalid_request",
                "error_description": "redirect_uri mismatch with client registered URI"
            }), 400
        effective_redirect_uri = redirect_uri
    else:
        effective_redirect_uri = registered_uris[0] if registered_uris else client['redirect_uri']

    if code_challenge and not code_challenge_method:
        code_challenge_method = 'S256'
    if code_challenge_method:
        code_challenge_method = code_challenge_method.upper()
        if code_challenge_method not in ['S256', 'PLAIN']:
            return jsonify({"error": "invalid_request", "error_description": "Unsupported code_challenge_method"}), 400

    if not session.get('logged_in'):
        return redirect(url_for('login', next=request.url))

    username = session.get('username')
    group = resolve_user_group(username)
    if group == 'quarantine':
        return jsonify({
            "error": "access_denied",
            "error_description": "User account is in quarantine (VLAN 99). Network access prohibited."
        }), 403

    code = DBManager.create_auth_code(
        client_id=client_id,
        username=username,
        redirect_uri=effective_redirect_uri,
        code_challenge=code_challenge,
        code_challenge_method=code_challenge_method,
        nonce=nonce
    )
    
    DBManager.add_audit_log(
        actor=username,
        action="SSO_AUTHORIZE_SUCCESS",
        target=client_id,
        new_value=f"Single Sign-On access granted for client: {client['client_name']}",
        ip=request.remote_addr
    )

    delim = '&' if '?' in effective_redirect_uri else '?'
    return redirect(f"{effective_redirect_uri}{delim}code={code}&state={state}")

@app.route('/oauth/token', methods=['POST'])
def oauth_token():
    """OAuth 2.0 Token Endpoint (Đổi Authorization Code lấy JWT Access Token & ID Token RS256)."""
    grant_type = request.form.get('grant_type')
    code = request.form.get('code')
    client_id = request.form.get('client_id')
    client_secret = request.form.get('client_secret')

    # Hỗ trợ HTTP Basic Authentication cho Client Credentials
    if not client_id and request.authorization:
        client_id = request.authorization.username
        client_secret = request.authorization.password

    if grant_type != 'authorization_code':
        return jsonify({"error": "unsupported_grant_type"}), 400

    if not client_id:
        return jsonify({"error": "invalid_client", "error_description": "Missing client_id"}), 400

    client = DBManager.get_sso_client(client_id)
    # Xác minh client_secret bằng hash an toàn và hmac.compare_digest chống Timing Attack
    if not client or not verify_client_secret(client['client_secret'], client_secret):
        return jsonify({"error": "invalid_client", "error_description": "Bad client credentials"}), 401

    auth_record = DBManager.consume_auth_code(code, client_id)
    if not auth_record:
        return jsonify({"error": "invalid_grant", "error_description": "Authorization code expired or already consumed"}), 400

    # Khắc phục lỗ hổng redirect_uri: Bắt buộc truyền redirect_uri và phải khớp chính xác với lần authorize
    req_redirect_uri = request.form.get('redirect_uri')
    if not req_redirect_uri or not hmac.compare_digest(req_redirect_uri, auth_record['redirect_uri']):
        return jsonify({"error": "invalid_grant", "error_description": "redirect_uri mismatch or missing"}), 400

    # Xác thực PKCE (RFC 7636) nếu code_challenge đã được đăng ký lúc authorize
    if auth_record.get('code_challenge'):
        code_verifier = request.form.get('code_verifier')
        if not code_verifier:
            return jsonify({"error": "invalid_grant", "error_description": "code_verifier required for PKCE-protected code"}), 400
        if not verify_pkce(code_verifier, auth_record['code_challenge'], auth_record.get('code_challenge_method')):
            return jsonify({"error": "invalid_grant", "error_description": "PKCE code_verifier validation failed"}), 400

    username = auth_record['username']
    group = resolve_user_group(username)
    if group == 'quarantine':
        return jsonify({
            "error": "access_denied",
            "error_description": "User account is in quarantine (VLAN 99). Token issuance denied."
        }), 403

    vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
    vlan = vlan_map.get(group, 99)

    u_info = ldap_client.get_user_info(username)
    name = (u_info['cn'] if u_info else None) or (ADMIN_USERS.get(username, {}).get('name')) or username
    email = (u_info['mail'] if u_info else None) or f"{username}@ptit.edu.vn"

    jti = secrets.token_hex(16)
    user_info = {
        "username": username,
        "name": name,
        "email": email,
        "group": group,
        "vlan": vlan,
        "auth_time": int(time.time()),
        "jti": jti
    }

    base_url = request.host_url.rstrip('/')
    scope = request.form.get('scope', 'openid profile email groups vlan')

    # Phân tách rõ ràng Payload Access Token và ID Token theo chuẩn RFC 6749 & OpenID Connect Core 1.0
    access_token = create_access_token(
        user_info=user_info,
        client_id=client_id,
        scope=scope,
        expires_in=3600,
        issuer=base_url
    )
    id_token = create_id_token(
        user_info=user_info,
        client_id=client_id,
        nonce=auth_record.get('nonce'),
        access_token=access_token,
        expires_in=3600,
        issuer=base_url
    )

    # Ghi nhận phiên ứng dụng vệ tinh vào DB để quản lý Single Logout (SLO) & Anti-Replay
    current_sid = getattr(session, 'sid', None) or request.args.get('sid') or request.form.get('sid') or secrets.token_hex(6)
    DBManager.record_sso_client_session(session_id=current_sid, client_id=client_id, username=username, access_token_jti=jti)

    return jsonify({
        "access_token": access_token,
        "token_type": "Bearer",
        "expires_in": 3600,
        "id_token": id_token,
        "scope": scope
    })

@app.route('/oauth/userinfo')
def oauth_userinfo():
    """OpenID Connect UserInfo Endpoint (Xác thực Access Token RS256 & kiểm tra Issuer/Audience)."""
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({"error": "unauthorized", "error_description": "Bearer token required in Authorization header"}), 401
    
    token = auth_header.split(' ', 1)[1].strip()
    try:
        base_url = request.host_url.rstrip('/')
        claims = verify_jwt(token, expected_iss=base_url)
        
        # Chống Session Replay Attack: Kiểm tra xem token jti có bị thu hồi bởi SLO không
        jti = claims.get('jti')
        if jti and not DBManager.is_sso_session_valid(session_id=None, jti=jti):
            return jsonify({
                "error": "invalid_token",
                "error_description": "Token has been revoked by Single Logout (SLO). Session Replay Attack blocked."
            }), 401
        
        username = claims.get('sub')
        group = resolve_user_group(username)
        vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
        vlan = vlan_map.get(group, 99)

        return jsonify({
            "sub": username,
            "name": username,
            "email": f"{username}@ptit.edu.vn",
            "group": group,
            "vlan": vlan
        })
    except Exception as e:
        return jsonify({"error": "invalid_token", "error_description": str(e)}), 401

# ====================================================================
# CÁC WEBSITE MÔ PHỎNG RIÊNG BIỆT & SINGLE SIGN-ON (SSO) FLOW
# ====================================================================
def get_or_create_app_session(client_id: str):
    """
    Kiểm tra và thiết lập phiên cho từng ứng dụng mô phỏng qua SSO IdP.
    Chống tấn công chiếm phiên (Session Replay Attack) bằng cách kiểm tra hiệu lực phiên với IdP.
    """
    if not session.get('logged_in'):
        return None, redirect(url_for('login', next=request.url))
    
    current_sid = getattr(session, 'sid', None)
    username = session.get('username')
    client_ip = request.remote_addr or '127.0.0.1'

    # 1. Kiểm tra nếu IP đang bị cách ly / chặn trong hệ thống
    ip_lock = DBManager.check_dashboard_ip_lock(client_ip)
    if ip_lock['is_blocked']:
        session.pop(f'app_{client_id}_active', None)
        flash(f'ĐỊA CHỈ IP BỊ CHẶN: IP của bạn ({client_ip}) đang bị cách ly. Không được phép truy cập ứng dụng!', 'danger')
        return None, redirect(url_for('sso_portal'))

    # 2. Kiểm tra nếu tài khoản đang bị cách ly trong LDAP (VLAN 99)
    group = resolve_user_group(username)
    vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
    vlan = vlan_map.get(group, 99)

    if group == 'quarantine' or vlan == 99:
        session.pop(f'app_{client_id}_active', None)
        flash('TÀI KHOẢN ĐANG BỊ CÁCH LY (VLAN 99)! Toàn bộ quyền truy cập vào các ứng dụng nội bộ đã bị khóa. Vui lòng liên hệ Quản trị viên để được mở khóa.', 'danger')
        return None, redirect(url_for('sso_portal'))

    # 3. Chống Session Replay Attack: Kiểm tra xem phiên SSO Master hoặc Client có bị thu hồi bởi SLO không
    if current_sid and username:
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT is_active, logged_out_at FROM sso_sessions WHERE session_id = %s", (current_sid,))
                m_row = cursor.fetchone()
                if m_row and (m_row.get('is_active') == 0 or m_row.get('logged_out_at') is not None):
                    session.pop(f'app_{client_id}_active', None)
                    flash('Phiên làm việc đã bị thu hồi do Single Logout (SLO). Đã ngăn chặn tấn công chiếm phiên (Session Replay Attack) thành công! Vui lòng đăng nhập lại.', 'warning')
                    return None, redirect(url_for('login'))
                elif not m_row:
                    DBManager.record_sso_master_session(current_sid, username, client_ip, request.user_agent.string)
        finally:
            conn.close()

    if not DBManager.is_sso_session_valid(session_id=current_sid, client_id=client_id):
        session.pop(f'app_{client_id}_active', None)
        flash('Phiên làm việc đã bị thu hồi do Single Logout (SLO). Đã ngăn chặn tấn công chiếm phiên (Session Replay Attack) thành công! Vui lòng đăng nhập lại.', 'warning')
        return None, redirect(url_for('login'))

    # Ghi nhận client session vào DB
    jti = secrets.token_hex(16)
    DBManager.record_sso_client_session(session_id=current_sid, client_id=client_id, username=username, access_token_jti=jti)
    session[f'app_{client_id}_active'] = True

    group = resolve_user_group(username)
    vlan_map = {'quantri': 10, 'sinhvien': 20, 'giangvien': 30, 'quarantine': 99}
    vlan = vlan_map.get(group, 99)

    user_info = {
        'username': username,
        'name': session.get('display_name', username),
        'email': f"{username}@ptit.edu.vn",
        'group': group,
        'vlan': vlan,
        'role': session.get('role', 'user')
    }
    return user_info, None

@app.route('/sso/simulate-app/<client_id>')
def sso_simulate_app(client_id):
    """Điều hướng tới Website mô phỏng riêng biệt tương ứng theo client_id."""
    username = session.get('username')
    client_ip = request.remote_addr or '127.0.0.1'
    ip_lock = DBManager.check_dashboard_ip_lock(client_ip)
    if ip_lock['is_blocked']:
        flash(f'ĐỊA CHỈ IP BỊ CHẶN: IP của bạn ({client_ip}) đang bị cách ly. Không thể truy cập ứng dụng.', 'danger')
        return redirect(url_for('sso_portal'))

    group = resolve_user_group(username)
    if group == 'quarantine':
        flash('TÀI KHOẢN ĐANG BỊ CÁCH LY (VLAN 99)! Toàn bộ quyền truy cập ứng dụng đã bị khóa.', 'danger')
        return redirect(url_for('sso_portal'))

    app_map = {
        'qldt_lms': 'app_qldt',
        'elibrary': 'app_elibrary',
        'vpn_portal': 'app_vpn',
        'webmail': 'app_webmail',
        'nac_admin': 'index'
    }
    endpoint = app_map.get(client_id)
    if endpoint:
        return redirect(url_for(endpoint))
    flash("Ứng dụng không tồn tại", "danger")
    return redirect(url_for('sso_portal'))

@app.route('/apps/qldt')
def app_qldt():
    """Website mô phỏng: Cổng Đào tạo & Quản lý Học tập LMS."""
    user_info, err = get_or_create_app_session('qldt_lms')
    if err:
        return err
    return render_template('apps/qldt.html', user=user_info, session_id=session.sid, client_id='qldt_lms')

@app.route('/apps/elibrary')
def app_elibrary():
    """Website mô phỏng: Thư viện Số & Học liệu PTIT."""
    user_info, err = get_or_create_app_session('elibrary')
    if err:
        return err
    return render_template('apps/elibrary.html', user=user_info, session_id=session.sid, client_id='elibrary')

@app.route('/apps/vpn')
def app_vpn():
    """Website mô phỏng: Cổng Truy cập Từ xa Zero-Trust VPN Gateway."""
    user_info, err = get_or_create_app_session('vpn_portal')
    if err:
        return err
    return render_template('apps/vpn.html', user=user_info, session_id=session.sid, client_id='vpn_portal')

@app.route('/apps/webmail')
def app_webmail():
    """Website mô phỏng: Hệ thống Thư điện tử PTIT Webmail."""
    user_info, err = get_or_create_app_session('webmail')
    if err:
        return err
    username = user_info.get('username') if user_info else ''
    user_email = user_info.get('email') if user_info else ''
    user_reset_emails = [e for e in SIMULATED_OUTBOX if e.get('username') == username or e.get('to') == user_email]
    return render_template('apps/webmail.html', user=user_info, session_id=session.sid, client_id='webmail', reset_emails=user_reset_emails)

# ====================================================================
# SINGLE LOGOUT (SLO) & SESSION REVOCATION ENDPOINTS
# ====================================================================
@app.route('/sso/single-logout')
def sso_single_logout():
    """
    Kích hoạt Single Logout (SLO):
    Hủy toàn bộ phiên Master tại Cổng SSO và tất cả các phiên làm việc trên các Website liên kết.
    Ngăn chặn triệt để tấn công chiếm phiên (Session Replay Attack).
    """
    username = session.get('username', 'UNKNOWN')
    current_sid = getattr(session, 'sid', None) or request.args.get('sid')
    
    revoked_count = DBManager.terminate_sso_single_logout(session_id=current_sid, username=username if not current_sid else None)
    
    DBManager.add_audit_log(
        actor=username,
        action="SSO_SINGLE_LOGOUT",
        target="ALL_CONNECTED_APPS",
        new_value=f"Kích hoạt Single Logout (SLO). Thu hồi thành công {revoked_count} phiên ứng dụng vệ tinh.",
        ip=request.remote_addr
    )
    
    session.clear()
    if current_sid and current_sid in app.session_interface.store:
        app.session_interface.store.pop(current_sid, None)
    flash('Bạn đã thực hiện Đăng xuất tập trung (Single Logout - SLO). Toàn bộ phiên làm việc trên các Website liên kết đã tự động hết hạn an toàn (Chống Session Replay Attack)!', 'success')
    resp = make_response(redirect(url_for('login')))
    resp.delete_cookie('nac_session_sid', path='/')
    return resp

@app.route('/oauth/logout', methods=['GET', 'POST'])
def oauth_logout():
    """OpenID Connect RP-Initiated Logout Endpoint (RFC 8414 / OIDC Core)."""
    post_logout_redirect_uri = request.args.get('post_logout_redirect_uri') or request.form.get('post_logout_redirect_uri')
    client_id = request.args.get('client_id') or request.form.get('client_id')
    current_sid = getattr(session, 'sid', None) or request.args.get('sid')
    username = session.get('username')

    revoked_count = DBManager.terminate_sso_single_logout(session_id=current_sid, username=username)
    DBManager.add_audit_log(
        actor=username or 'CLIENT_APP',
        action="OIDC_RP_LOGOUT",
        target=client_id or 'ALL_APPS',
        new_value=f"SLO triggered via RP-Initiated Logout. Revoked {revoked_count} app sessions.",
        ip=request.remote_addr
    )
    session.clear()
    if current_sid and current_sid in app.session_interface.store:
        app.session_interface.store.pop(current_sid, None)
    if post_logout_redirect_uri and is_safe_redirect_url(post_logout_redirect_uri):
        resp = make_response(redirect(post_logout_redirect_uri))
    else:
        flash('Đăng xuất thành công qua OIDC Single Logout.', 'info')
        resp = make_response(redirect(url_for('login')))
    resp.delete_cookie('nac_session_sid', path='/')
    return resp

@app.route('/logout')
def logout():
    """Đăng xuất khỏi Dashboard và kích hoạt Single Logout (SLO) cho các ứng dụng vệ tinh."""
    actor = session.get('username', 'UNKNOWN')
    current_sid = getattr(session, 'sid', None) or request.args.get('sid')
    
    # Hủy toàn bộ phiên SSO liên kết
    revoked_count = DBManager.terminate_sso_single_logout(session_id=current_sid, username=actor if not current_sid else None)
    
    DBManager.add_audit_log(
        actor=actor,
        action="DASHBOARD_LOGOUT",
        target="SYSTEM",
        new_value=f"Đăng xuất và kích hoạt SLO. Thu hồi {revoked_count} phiên ứng dụng.",
        ip=request.remote_addr
    )
    session.clear()
    if current_sid and current_sid in app.session_interface.store:
        app.session_interface.store.pop(current_sid, None)
    flash('Bạn đã đăng xuất an toàn khỏi Cổng SSO và các Website liên kết.', 'info')
    resp = make_response(redirect(url_for('login')))
    resp.delete_cookie('nac_session_sid', path='/')
    return resp

# ==========================================================
# DASHBOARD VIEWS
# ==========================================================
@app.route('/')
@login_required
def index():
    if session.get('role') == 'user':
        return redirect(url_for('sso_portal'))

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
@staff_required
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
        current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
        return redirect(url_for('users_list', sid=current_sid))

    # Kiểm tra chính sách mật khẩu mạnh (Tối thiểu 12 ký tự, hoa, thường, số, ký tự đặc biệt)
    is_valid_pw, pw_err = validate_password_policy(password)
    if not is_valid_pw:
        flash(f'Không thể tạo tài khoản "{uid}": {pw_err}', 'warning')
        current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
        return redirect(url_for('users_list', sid=current_sid))

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
        
        # 1. Thu hồi tức thì toàn bộ phiên SSO Master và các phiên Client của user (Instant SLO)
        revoked_count = DBManager.terminate_sso_single_logout(username=uid)

        # 2. Chặn luôn toàn bộ địa chỉ IP liên kết với tài khoản này
        blocked_ips = DBManager.block_user_ip(username=uid, lock_minutes=1440)
        blocked_ips_str = ", ".join(blocked_ips) if blocked_ips else "Không có IP nào được ghi nhận"

        # Ghi nhận sự kiện cách ly vào bảng quarantine_events (Append-only)
        DBManager.record_quarantine_event(
            username=uid,
            event_type='QUARANTINE',
            reason=f'Cách ly thủ công bởi quản trị viên. Thu hồi {revoked_count} phiên SSO, chặn IP: {blocked_ips_str}',
            failed_count=0,
            source=session.get('username') or 'admin',
            previous_group=old_group
        )

        DBManager.add_audit_log(
            actor=session.get('username'),
            action="MANUAL_QUARANTINE",
            target=uid,
            old_val=f"Group: {old_group}",
            new_val=f"Group: quarantine (VLAN 99) | Blocked IPs: {blocked_ips_str} | Revoked SSO: {revoked_count}",
            ip=request.remote_addr
        )
        flash(f'Đã đưa người dùng {uid} vào diện cách ly (VLAN 99), thu hồi toàn bộ {revoked_count} phiên SSO và đã chặn IP: {blocked_ips_str}.', 'warning')
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
        
        # 2. Giải phóng toàn bộ địa chỉ IP bị chặn liên kết với tài khoản này
        unblocked_ips = DBManager.unblock_user_ip(username=uid)
        unblocked_ips_str = ", ".join(unblocked_ips) if unblocked_ips else "Không có"

        # 3. Ghi nhận sự kiện giải phóng vào bảng quarantine_events (Append-only)
        DBManager.record_quarantine_event(
            username=uid,
            event_type='RELEASE',
            reason=f'Mở khóa bởi quản trị viên và khôi phục về nhóm {target_group}. Giải phóng IP: {unblocked_ips_str}',
            failed_count=0,
            source=session.get('username') or 'admin',
            previous_group='quarantine'
        )

        # 4. Ghi log kiểm toán (Hash-Chain chống chối bỏ)
        DBManager.add_audit_log(
            actor=session.get('username'),
            action="UNLOCK_USER",
            target=uid,
            old_val="Group: quarantine",
            new_val=f"Group: {target_group} | Unblocked IPs: {unblocked_ips_str}",
            ip=request.remote_addr
        )
        flash(f'Đã mở khóa tài khoản {uid}, khôi phục về nhóm {target_group} và giải phóng IP: {unblocked_ips_str}.', 'success')
    except Exception as e:
        flash(f'Lỗi khi mở khóa: {e}', 'danger')
    current_sid = getattr(g, 'sid', None) or request.args.get('sid') or request.form.get('sid')
    return redirect(url_for('users_list', sid=current_sid))

@app.route('/api/live-status')
@login_required
@staff_required
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
@staff_required
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
@staff_required
def logs_view():
    search_user = request.args.get('user', '').strip()
    logs = DBManager.get_auth_logs(limit=150, username=search_user if search_user else None)
    return render_template('logs.html', logs=logs, search_user=search_user)

@app.route('/sessions')
@login_required
@staff_required
def sessions_view():
    sessions = DBManager.get_active_sessions()
    return render_template('sessions.html', sessions=sessions)

@app.route('/audit')
@login_required
@staff_required
def audit_view():
    audit_logs = DBManager.get_audit_logs(limit=150)
    audit_integrity = DBManager.verify_audit_chain()
    return render_template('audit.html', audit_logs=audit_logs, audit_integrity=audit_integrity)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
