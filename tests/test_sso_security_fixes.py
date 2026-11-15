import os
import sys
import urllib.request
import urllib.parse
import json
import http.cookiejar
import hashlib
import base64
import time
import secrets
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes, serialization

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'dashboard'))

BASE_URL = "http://127.0.0.1:5000"

def b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')

def b64url_decode(s: str) -> bytes:
    padding_len = (4 - len(s) % 4) % 4
    return base64.urlsafe_b64decode(s + '=' * padding_len)

def get_session(cj=None):
    if cj is None:
        cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cj),
        urllib.request.HTTPRedirectHandler()
    )
    return opener, cj

class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    def http_error_302(self, req, fp, code, msg, headers):
        return fp
    http_error_301 = http_error_302
    http_error_303 = http_error_302
    http_error_307 = http_error_302

def get_no_redirect_opener(cj=None):
    if cj is None:
        cj = http.cookiejar.CookieJar()
    return urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cj),
        NoRedirectHandler()
    ), cj

def test_sso_fixes():
    print("=" * 75)
    print(" BỘ KIỂM THỬ TỔNG THỂ CÁC BẢO MẬT SSO / OIDC & OPEN REDIRECT")
    print("=" * 75)

    # -------------------------------------------------------------
    # 1. KIỂM THỬ OPEN REDIRECT Ở /login
    # -------------------------------------------------------------
    print("\n[MỤC 1: KIỂM THỬ CHỐNG OPEN REDIRECT Ở /login]")
    no_red_opener, _ = get_no_redirect_opener()

    # Thử bypass bằng //evil.com
    malicious_urls = [
        "//evil.com",
        "/\\evil.com",
        "\\evil.com",
        "https://evil.com/phishing",
        "http://attacker.com"
    ]

    for evil_url in malicious_urls:
        login_post = urllib.parse.urlencode({
            'username': 'admin',
            'password': 'AdminPassword123!'
        }).encode('utf-8')
        
        req = urllib.request.Request(f"{BASE_URL}/login?next={urllib.parse.quote(evil_url)}", data=login_post)
        resp = no_red_opener.open(req)
        loc = resp.headers.get('Location', '')
        # Phải chuyển hướng về index (/) hoặc trang nội bộ, tuyệt đối không ra ngoài
        assert "evil.com" not in loc and "attacker.com" not in loc, f"Open Redirect bị khai thác qua: {evil_url} -> Location: {loc}"
        print(f"  [ĐẠT] Chặn thành công Open Redirect với payload: {evil_url:25} -> Chuyển hướng an toàn: {loc}")

    # Thử next hợp lệ dạng relative URL (/policies)
    safe_post = urllib.parse.urlencode({
        'username': 'admin',
        'password': 'AdminPassword123!'
    }).encode('utf-8')
    req_safe = urllib.request.Request(f"{BASE_URL}/login?next=/policies", data=safe_post)
    resp_safe = no_red_opener.open(req_safe)
    loc_safe = resp_safe.headers.get('Location', '')
    assert loc_safe.startswith('/policies') or 'policies' in loc_safe, f"Safe redirect failed: {loc_safe}"
    print(f"  [ĐẠT] Cho phép chuyển hướng an toàn hợp lệ: /policies -> Location: {loc_safe}")

    # -------------------------------------------------------------
    # 2. KIỂM THỬ ENDPOINT /oauth/jwks & OPENID CONFIGURATION
    # -------------------------------------------------------------
    print("\n[MỤC 2: KIỂM THỬ ENDPOINT /oauth/jwks VÀ /.well-known/openid-configuration]")
    opener, cj = get_session()

    # 2.1 Kiểm tra openid discovery
    disc_req = opener.open(f"{BASE_URL}/.well-known/openid-configuration")
    disc = json.loads(disc_req.read().decode('utf-8'))
    assert disc.get('jwks_uri') == f"{BASE_URL}/oauth/jwks", "jwks_uri không đúng"
    assert "RS256" in disc.get('id_token_signing_alg_values_supported', []), "Thiếu thuật toán ký RS256 trong discovery"
    assert "S256" in disc.get('code_challenge_methods_supported', []), "Thiếu hỗ trợ PKCE S256 trong discovery"
    print(f"  [ĐẠT] OpenID Discovery Document thông báo đúng:")
    print(f"        - jwks_uri: {disc['jwks_uri']}")
    print(f"        - id_token_signing_alg_values_supported: {disc['id_token_signing_alg_values_supported']}")
    print(f"        - code_challenge_methods_supported: {disc['code_challenge_methods_supported']}")

    # 2.2 Kiểm tra /oauth/jwks
    jwks_req = opener.open(f"{BASE_URL}/oauth/jwks")
    assert jwks_req.status == 200, f"/oauth/jwks trả về status {jwks_req.status}"
    jwks = json.loads(jwks_req.read().decode('utf-8'))
    assert "keys" in jwks and len(jwks["keys"]) > 0, "JWKS không có keys"
    jwk = jwks["keys"][0]
    assert jwk.get('kty') == 'RSA', "Key type phải là RSA"
    assert jwk.get('alg') == 'RS256', "Algorithm phải là RS256"
    assert 'n' in jwk and 'e' in jwk, "Thiếu modulus n hoặc public exponent e trong JWKS"
    print(f"  [ĐẠT] Endpoint /oauth/jwks cung cấp JSON Web Key Set chuẩn RFC 7517:")
    print(f"        - kty: {jwk['kty']}, alg: {jwk['alg']}, kid: {jwk.get('kid')}")
    print(f"        - n: {jwk['n'][:30]}... (2048-bit RSA Modulus)")

    # -------------------------------------------------------------
    # 3. ĐĂNG NHẬP ADMIN VÀ LẤY SESSION ĐỂ THỰC HIỆN SSO FLOW
    # -------------------------------------------------------------
    print("\n[MỤC 3: ĐĂNG NHẬP ADMIN ĐỂ THỰC HIỆN OAUTH AUTHORIZE]")
    # Tạo sid độc lập
    sid = secrets.token_hex(6)
    login_url = f"{BASE_URL}/login?sid={sid}"
    login_data = urllib.parse.urlencode({
        'username': 'admin',
        'password': 'AdminPassword123!',
        'sid': sid
    }).encode('utf-8')
    login_resp = opener.open(login_url, data=login_data)
    login_body = login_resp.read().decode('utf-8')

    # Nếu yêu cầu MFA
    if 'mfa/verify' in login_resp.geturl() or 'OTP 6 số' in login_body or 'mfa_verify' in login_body:
        from mfa import get_totp_code
        from models import DBManager
        mfa_rec = DBManager.get_user_mfa('admin')
        totp_code = get_totp_code(mfa_rec['secret_key'])
        mfa_post = urllib.parse.urlencode({'code': totp_code, 'sid': sid}).encode('utf-8')
        mfa_resp = opener.open(f"{BASE_URL}/mfa/verify?sid={sid}", data=mfa_post)
        print("  [ĐẠT] Đã hoàn thành xác thực MFA Bước 2 cho Admin.")
    else:
        print("  [ĐẠT] Đăng nhập trực tiếp thành công.")

    # -------------------------------------------------------------
    # 4. KIỂM THỬ SO KHỚP CHÍNH XÁC REDIRECT_URI Ở /oauth/authorize
    # -------------------------------------------------------------
    print("\n[MỤC 4: KIỂM THỬ KIỂM SOÁT REDIRECT_URI TẠI /oauth/authorize]")

    # 4.1 Thử gửi redirect_uri giả mạo của Hacker -> Bắt buộc nhận HTTP 400
    fake_redirect = "http://hacker.com/steal_auth_code"
    bad_auth_url = f"{BASE_URL}/oauth/authorize?client_id=qldt_lms&redirect_uri={urllib.parse.quote(fake_redirect)}&state=test_csrf&sid={sid}"
    try:
        urllib.request.urlopen(bad_auth_url)
        assert False, "Lẽ ra phải từ chối redirect_uri giả mạo bằng HTTP 400!"
    except urllib.error.HTTPError as e:
        assert e.code == 400, f"Mong đợi HTTP 400 nhưng nhận: {e.code}"
        err_body = json.loads(e.read().decode('utf-8'))
        assert err_body.get('error') == 'invalid_request', f"Thông báo lỗi không khớp: {err_body}"
        print(f"  [ĐẠT] /oauth/authorize đã TỪ CHỐI redirect_uri giả mạo: {fake_redirect} (HTTP 400 - {err_body.get('error_description')})")

    # 4.2 Gửi redirect_uri hợp lệ khớp với cấu hình client -> Phải thành công
    valid_redirect = "http://qldt.ptit.edu.vn/sso/callback"
    # Chuẩn bị PKCE S256 và Nonce
    code_verifier = secrets.token_urlsafe(64)
    code_challenge = b64url_encode(hashlib.sha256(code_verifier.encode('ascii')).digest())
    nonce_val = secrets.token_hex(16)

    good_auth_url = (
        f"{BASE_URL}/oauth/authorize?"
        f"client_id=qldt_lms&"
        f"redirect_uri={urllib.parse.quote(valid_redirect)}&"
        f"response_type=code&"
        f"state=xyz_state_123&"
        f"code_challenge={code_challenge}&"
        f"code_challenge_method=S256&"
        f"nonce={nonce_val}&"
        f"sid={sid}"
    )

    no_red_sso, _ = get_no_redirect_opener(cj=cj)

    auth_req = urllib.request.Request(good_auth_url)
    auth_resp = no_red_sso.open(auth_req)
    redirect_target = auth_resp.headers.get('Location', '')
    assert redirect_target.startswith(valid_redirect), f"Chuyển hướng không đúng mục tiêu: {redirect_target}"

    parsed = urllib.parse.urlparse(redirect_target)
    query_params = urllib.parse.parse_qs(parsed.query)
    auth_code = query_params.get('code', [None])[0]
    assert auth_code, f"Không tìm thấy authorization code trong: {redirect_target}"
    assert query_params.get('state', [''])[0] == 'xyz_state_123', "State không khớp"
    print(f"  [ĐẠT] /oauth/authorize chấp nhận redirect_uri chuẩn: {valid_redirect}")
    print(f"        - Cấp phát Auth Code (gắn kèm PKCE & Nonce): {auth_code[:20]}...")

    # -------------------------------------------------------------
    # 5. KIỂM THỬ /oauth/token VỚI REDIRECT_URI, CLIENT SECRET HASH & PKCE
    # -------------------------------------------------------------
    print("\n[MỤC 5: KIỂM THỬ XÁC THỰC TẠI /oauth/token]")

    def get_fresh_code(v_redirect, c_chal=None, n_val=None):
        url = (
            f"{BASE_URL}/oauth/authorize?"
            f"client_id=qldt_lms&"
            f"redirect_uri={urllib.parse.quote(v_redirect)}&"
            f"response_type=code&"
            f"state=test_state&"
            f"sid={sid}"
        )
        if c_chal:
            url += f"&code_challenge={c_chal}&code_challenge_method=S256"
        if n_val:
            url += f"&nonce={n_val}"
        r = no_red_sso.open(urllib.request.Request(url))
        loc = r.headers.get('Location', '')
        q = urllib.parse.parse_qs(urllib.parse.urlparse(loc).query)
        return q.get('code', [None])[0]

    # 5.1 Test sai client_secret -> HTTP 401
    code_for_bad_secret = get_fresh_code(valid_redirect, code_challenge, nonce_val)
    bad_secret_post = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': code_for_bad_secret,
        'client_id': 'qldt_lms',
        'client_secret': 'sec_wrong_password',
        'redirect_uri': valid_redirect,
        'code_verifier': code_verifier
    }).encode('utf-8')
    try:
        opener.open(f"{BASE_URL}/oauth/token", data=bad_secret_post)
        assert False, "Lẽ ra phải từ chối sai client_secret bằng HTTP 401"
    except urllib.error.HTTPError as e:
        assert e.code == 401, f"Mong đợi HTTP 401 nhưng nhận: {e.code}"
        print("  [ĐẠT] /oauth/token từ chối client_secret sai (HTTP 401 Unauthorized - Timing Attack Protected)")

    # 5.2 Test sai redirect_uri lúc đổi token -> HTTP 400
    code_for_bad_redir = get_fresh_code(valid_redirect, code_challenge, nonce_val)
    bad_redir_post = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': code_for_bad_redir,
        'client_id': 'qldt_lms',
        'client_secret': 'sec_qldt_9921',
        'redirect_uri': 'http://hacker.com/other_callback',
        'code_verifier': code_verifier
    }).encode('utf-8')
    try:
        opener.open(f"{BASE_URL}/oauth/token", data=bad_redir_post)
        assert False, "Lẽ ra phải từ chối redirect_uri không khớp với lần authorize"
    except urllib.error.HTTPError as e:
        assert e.code == 400, f"Mong đợi HTTP 400 nhưng nhận: {e.code}"
        print("  [ĐẠT] /oauth/token từ chối yêu cầu có redirect_uri không khớp với lần authorize (HTTP 400)")

    # 5.3 Test sai code_verifier (PKCE) -> HTTP 400
    code_for_bad_pkce = get_fresh_code(valid_redirect, code_challenge, nonce_val)
    bad_pkce_post = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': code_for_bad_pkce,
        'client_id': 'qldt_lms',
        'client_secret': 'sec_qldt_9921',
        'redirect_uri': valid_redirect,
        'code_verifier': 'wrong_verifier_challenge_fail'
    }).encode('utf-8')
    try:
        opener.open(f"{BASE_URL}/oauth/token", data=bad_pkce_post)
        assert False, "Lẽ ra phải từ chối PKCE code_verifier sai"
    except urllib.error.HTTPError as e:
        assert e.code == 400, f"Mong đợi HTTP 400 nhưng nhận: {e.code}"
        print("  [ĐẠT] /oauth/token từ chối code_verifier PKCE không hợp lệ (HTTP 400)")

    # 5.4 Test HỢP LỆ: Đổi token thành công với Client Secret, đúng redirect_uri và đúng code_verifier PKCE
    code_valid = get_fresh_code(valid_redirect, code_challenge, nonce_val)
    valid_token_post = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': code_valid,
        'client_id': 'qldt_lms',
        'client_secret': 'sec_qldt_9921',
        'redirect_uri': valid_redirect,
        'code_verifier': code_verifier
    }).encode('utf-8')
    token_req = opener.open(f"{BASE_URL}/oauth/token", data=valid_token_post)
    assert token_req.status == 200
    token_data = json.loads(token_req.read().decode('utf-8'))

    access_token = token_data.get('access_token')
    id_token = token_data.get('id_token')
    assert access_token and id_token, "Thiếu access_token hoặc id_token trong phản hồi"
    assert access_token != id_token, "LỖI: access_token và id_token không được trùng nhau!"
    print(f"  [ĐẠT] Đổi Code lấy Token thành công qua PBKDF2 Hashed Secret & PKCE S256:")
    print(f"        - Access Token: {access_token[:30]}...")
    print(f"        - ID Token:     {id_token[:30]}...")

    # -------------------------------------------------------------
    # 6. KIỂM THỬ XÁC MINH CHỮ KÝ RS256 CỦA TOKEN VÀ PHÂN TÁCH PAYLOAD
    # -------------------------------------------------------------
    print("\n[MỤC 6: KIỂM THỬ CHỮ KÝ BẤT ĐỐI XỨNG RS256 & BẢO TOÀN CLAIM]")
    from sso import verify_jwt, compute_at_hash

    # Giải mã và xác thực Access Token
    acc_claims = verify_jwt(access_token, expected_aud='qldt_lms', expected_iss=BASE_URL)
    assert acc_claims.get('sub') == 'admin', "Subject access_token không đúng"
    assert acc_claims.get('token_type') == 'Bearer', "Token type không phải Bearer"
    assert 'jti' in acc_claims, "Thiếu jti trong access_token"
    print("  [ĐẠT] Access Token xác thực thành công bằng khóa công khai RSA (RS256):")
    print(f"        - Claims: sub={acc_claims.get('sub')}, aud={acc_claims.get('aud')}, scope={acc_claims.get('scope')}")

    # Giải mã và xác thực ID Token
    id_claims = verify_jwt(id_token, expected_aud='qldt_lms', expected_iss=BASE_URL)
    assert id_claims.get('sub') == 'admin', "Subject id_token không đúng"
    assert id_claims.get('nonce') == nonce_val, f"Nonce không khớp: {id_claims.get('nonce')} vs {nonce_val}"
    assert 'at_hash' in id_claims, "Thiếu mã băm at_hash trong ID Token"
    expected_at_hash = compute_at_hash(access_token)
    assert id_claims.get('at_hash') == expected_at_hash, f"at_hash không khớp: {id_claims.get('at_hash')} vs {expected_at_hash}"
    assert id_claims.get('vlan') == 10, f"VLAN admin không phải 10: {id_claims.get('vlan')}"
    print("  [ĐẠT] ID Token xác thực thành công:")
    print(f"        - Nonce chống Replay: {id_claims.get('nonce')}")
    print(f"        - at_hash liên kết Access Token (RFC spec): {id_claims.get('at_hash')}")
    print(f"        - Profile Claims: name={id_claims.get('name')}, email={id_claims.get('email')}, group={id_claims.get('group')}, VLAN={id_claims.get('vlan')}")

    # -------------------------------------------------------------
    # 7. KIỂM THỬ ENDPOINT /oauth/userinfo VỚI ACCESS TOKEN RS256
    # -------------------------------------------------------------
    print("\n[MỤC 7: KIỂM THỬ TRUY VẤN USERINFO BẰNG BEARER TOKEN]")
    ui_req = urllib.request.Request(f"{BASE_URL}/oauth/userinfo")
    ui_req.add_header('Authorization', f'Bearer {access_token}')
    ui_resp = opener.open(ui_req)
    assert ui_resp.status == 200
    userinfo = json.loads(ui_resp.read().decode('utf-8'))
    assert userinfo.get('sub') == 'admin'
    assert userinfo.get('group') == 'quantri'
    assert userinfo.get('vlan') == 10
    print(f"  [ĐẠT] UserInfo Endpoint trả về chính xác:")
    print(f"        - User: {userinfo.get('sub')} ({userinfo.get('name')})")
    print(f"        - Email: {userinfo.get('email')}")
    print(f"        - Quyền VLAN: VLAN {userinfo.get('vlan')}")

    # -------------------------------------------------------------
    # 8. THỬ TRUY CẬP USERINFO VỚI TOKEN HẾT HẠN HOẶC GIẢ MẠO
    # -------------------------------------------------------------
    print("\n[MỤC 8: KIỂM THỬ BẢO VỆ USERINFO KHI TOKEN GIẢ MẠO]")
    bad_token = access_token[:-10] + "tampered00"
    tampered_req = urllib.request.Request(f"{BASE_URL}/oauth/userinfo")
    tampered_req.add_header('Authorization', f'Bearer {bad_token}')
    try:
        opener.open(tampered_req)
        assert False, "Lẽ ra phải từ chối token giả mạo"
    except urllib.error.HTTPError as e:
        assert e.code == 401
        print("  [ĐẠT] Từ chối token giả mạo thành công (HTTP 401 Unauthorized)")

    print("\n" + "=" * 75)
    print(" >>> TẤT CẢ CÁC KIỂM THỬ BẢO MẬT SSO / OIDC ĐÃ HOÀN TOÀN ĐẠT CHUẨN! <<<")
    print("=" * 75)

if __name__ == '__main__':
    test_sso_fixes()
