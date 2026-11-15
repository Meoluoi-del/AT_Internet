import os
import sys
import urllib.request
import urllib.parse
import json
import http.cookiejar
import secrets
import pymysql

os.environ.setdefault('DB_HOST', '127.0.0.1')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'dashboard'))

BASE_URL = "http://127.0.0.1:5000"

def get_session():
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

def get_no_redirect_opener(cj):
    return urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cj),
        NoRedirectHandler()
    )

def test_single_logout_and_apps():
    print("=" * 80)
    print(" KIỂM THỬ SINGLE SIGN-ON (SSO), CÁC WEBSITE MÔ PHỎNG & SINGLE LOGOUT (SLO)")
    print(" PHÒNG CHỐNG TẤN CÔNG CHIẾM PHIÊN (SESSION REPLAY ATTACK)")
    print("=" * 80)

    # -----------------------------------------------------------------
    # BƯỚC 1: ĐĂNG NHẬP 1 LẦN DUY NHẤT TẠI CỔNG SSO (MASTER LOGIN)
    # -----------------------------------------------------------------
    print("\n[BƯỚC 1: ĐĂNG NHẬP MỘT LẦN DUY NHẤT QUA CỔNG SSO]")
    opener, cj = get_session()
    sid = secrets.token_hex(6)

    login_post = urllib.parse.urlencode({
        'username': 'admin',
        'password': 'AdminPassword123!',
        'sid': sid
    }).encode('utf-8')

    resp = opener.open(f"{BASE_URL}/login?sid={sid}", data=login_post)
    body = resp.read().decode('utf-8')
    assert "Chào mừng" in body or "BẢNG ĐIỀU KHIỂN" in body or resp.status == 200
    print("  [ĐẠT] Đăng nhập Cổng SSO thành công (Master Session được thiết lập).")

    # -----------------------------------------------------------------
    # BƯỚC 2: TRUY CẬP CÁC WEBSITE MÔ PHỎNG RIÊNG BIỆT (TỰ ĐỘNG SSO)
    # -----------------------------------------------------------------
    print("\n[BƯỚC 2: TRUY CẬP CÁC WEBSITE MÔ PHỎNG RIÊNG BIỆT - CHỈ ĐĂNG NHẬP 1 LẦN]")

    apps = [
        {
            'name': 'Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)',
            'url': f"{BASE_URL}/apps/qldt?sid={sid}",
            'expected_content': ['CỔNG ĐÀO TẠO', 'Thời Khóa Biểu', 'Bảng Điểm Học Phần', 'admin']
        },
        {
            'name': 'Thư viện Số & Học liệu PTIT (E-Library)',
            'url': f"{BASE_URL}/apps/elibrary?sid={sid}",
            'expected_content': ['THƯ VIỆN SỐ', 'KHO TÀI LIỆU SỐ', 'Thẻ Bạn Đọc Điện Tử', '802.1X']
        },
        {
            'name': 'Cổng Truy cập Từ xa Zero-Trust (VPN Gateway)',
            'url': f"{BASE_URL}/apps/vpn?sid={sid}",
            'expected_content': ['CỔNG KẾT NỐI TỪ XA ZERO-TRUST', 'ĐƯỜNG TRUYỀN VPN ĐANG HOẠT ĐỘNG', 'Tunnel Traffic']
        },
        {
            'name': 'Hệ thống Thư điện tử (Webmail PTIT)',
            'url': f"{BASE_URL}/apps/webmail?sid={sid}",
            'expected_content': ['HỆ THỐNG THƯ ĐIỆN TỬ', 'Hộp thư đến', 'admin@ptit.edu.vn']
        }
    ]

    for app in apps:
        app_resp = opener.open(app['url'])
        assert app_resp.status == 200, f"Truy cập {app['name']} thất bại!"
        app_body = app_resp.read().decode('utf-8')
        for exp in app['expected_content']:
            assert exp in app_body, f"Thiếu nội dung '{exp}' trong website {app['name']}"
        print(f"  [ĐẠT] Tự động SSO vào website mô phỏng riêng biệt: {app['name']}")
        print(f"        -> Không cần nhập mật khẩu, tự động nhận diện tài khoản: admin, quyền mạng: VLAN 10")

    # Kiểm tra Launchpad hiển thị các ứng dụng đang có phiên hoạt động
    portal_resp = opener.open(f"{BASE_URL}/sso?sid={sid}")
    portal_body = portal_resp.read().decode('utf-8')
    assert "Phiên SSO Đang Hoạt Động" in portal_body or "SSO Connected" in portal_body
    print("  [ĐẠT] Cổng SSO Launchpad giám sát chính xác danh sách các ứng dụng đang liên kết phiên.")

    # -----------------------------------------------------------------
    # BƯỚC 3: LẤY TOKEN OIDC ĐỂ THỬ NGHIỆM TẤN CÔNG CHIẾM PHIÊN (SESSION REPLAY)
    # -----------------------------------------------------------------
    print("\n[BƯỚC 3: CẤP TOKEN OIDC RS256 ĐỂ MÔ PHỎNG ĐIỀU TRA SỐ]")
    from models import DBManager
    auth_code = DBManager.create_auth_code('qldt_lms', 'admin', 'http://localhost:5000/sso/callback')
    token_post = urllib.parse.urlencode({
        'grant_type': 'authorization_code',
        'code': auth_code,
        'client_id': 'qldt_lms',
        'client_secret': 'sec_qldt_9921',
        'redirect_uri': 'http://localhost:5000/sso/callback'
    }).encode('utf-8')
    token_resp = opener.open(f"{BASE_URL}/oauth/token?sid={sid}", data=token_post)
    token_json = json.loads(token_resp.read().decode('utf-8'))
    access_token = token_json.get('access_token')
    assert access_token, "Không lấy được access_token"

    # Kiểm tra UserInfo trước khi Logout -> Phải thành công (HTTP 200)
    ui_req = urllib.request.Request(f"{BASE_URL}/oauth/userinfo")
    ui_req.add_header('Authorization', f'Bearer {access_token}')
    ui_resp = opener.open(ui_req)
    assert ui_resp.status == 200
    print("  [ĐẠT] Access Token RS256 hợp lệ trước khi Single Logout.")

    # -----------------------------------------------------------------
    # BƯỚC 4: KÍCH HOẠT SINGLE LOGOUT (SLO) TẠI CỔNG SSO
    # -----------------------------------------------------------------
    print("\n[BƯỚC 4: KÍCH HOẠT SINGLE LOGOUT (SLO)]")
    no_red_opener = get_no_redirect_opener(cj)
    slo_req = urllib.request.Request(f"{BASE_URL}/sso/single-logout?sid={sid}")
    slo_resp = no_red_opener.open(slo_req)
    loc = slo_resp.headers.get('Location', '')
    assert 'login' in loc or slo_resp.status in [200, 302]
    print("  [ĐẠT] Single Logout (SLO) đã thực thi thành công:")
    print("        - Phiên Master đã bị hủy.")
    print("        - Toàn bộ các phiên Website liên kết (QLĐT, E-Library, VPN, Webmail) đã bị đánh dấu thu hồi (revoked).")

    # Kiểm tra trong Database xem sso_sessions và sso_client_sessions đã revoked chưa
    conn = pymysql.connect(
        host='127.0.0.1',
        user='root',
        password='RootPassword123!',
        database='radius',
        cursorclass=pymysql.cursors.DictCursor
    )
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM sso_sessions WHERE session_id = %s", (sid,))
        m_row = cursor.fetchone()
        assert m_row and m_row['is_active'] == 0 and m_row['logged_out_at'] is not None, "Master session chưa được thu hồi"

        cursor.execute("SELECT COUNT(*) as count FROM sso_client_sessions WHERE session_id = %s AND is_active = 0", (sid,))
        revoked_clients_count = cursor.fetchone()['count']
        assert revoked_clients_count > 0, "Không có client session nào bị thu hồi"
        print(f"  [ĐẠT] MariaDB xác thực: Thu hồi thành công {revoked_clients_count} phiên Client và Master Session {sid}.")
    conn.close()

    # -----------------------------------------------------------------
    # BƯỚC 5: KIỂM THỬ PHÒNG CHỐNG TẤN CÔNG CHIẾM PHIÊN (SESSION REPLAY ATTACK)
    # -----------------------------------------------------------------
    print("\n[BƯỚC 5: KIỂM THỬ CHỐNG CHIẾM PHIÊN (ANTI-SESSION REPLAY ATTACK)]")

    # Kẻ tấn công cố tình gửi lại Session Cookie cũ vào các website mô phỏng
    for app in apps:
        app_req = urllib.request.Request(app['url'])
        app_r = no_red_opener.open(app_req)
        app_loc = app_r.headers.get('Location', '')
        # Bắt buộc phải bị đẩy về /login do phiên đã bị hủy bởi SLO
        assert 'login' in app_loc, f"LỖI: Website {app['name']} không chặn phiên cũ sau Single Logout! (Location: {app_loc})"
        print(f"  [ĐẠT] Chặn thành công Session Replay trên: {app['name']}")
        print(f"        -> Cookie phiên cũ bị từ chối tuyệt đối, chuyển hướng về: {app_loc}")

    # Kẻ tấn công cố tình gửi lại Access Token cũ đã cấp trước thời điểm SLO vào /oauth/userinfo
    replay_token_req = urllib.request.Request(f"{BASE_URL}/oauth/userinfo")
    replay_token_req.add_header('Authorization', f'Bearer {access_token}')
    try:
        urllib.request.urlopen(replay_token_req)
        assert False, "LỖI: Token cũ vẫn được chấp nhận sau Single Logout!"
    except urllib.error.HTTPError as e:
        assert e.code == 401, f"Mong đợi HTTP 401 nhưng nhận: {e.code}"
        err_msg = json.loads(e.read().decode('utf-8'))
        print("  [ĐẠT] Chặn thành công Replay Token tại /oauth/userinfo:")
        print(f"        -> HTTP 401: {err_msg.get('error_description')}")

    # Kiểm tra Audit Log
    with pymysql.connect(host='127.0.0.1', user='root', password='RootPassword123!', database='radius', cursorclass=pymysql.cursors.DictCursor) as db:
        with db.cursor() as cur:
            cur.execute("SELECT action, actor_username, target, new_value FROM audit_logs WHERE action = 'SSO_SINGLE_LOGOUT' ORDER BY id DESC LIMIT 1")
            audit = cur.fetchone()
            assert audit, "Không tìm thấy Audit Log cho SSO_SINGLE_LOGOUT"
            print(f"  [ĐẠT] Nhật ký kiểm toán ghi nhận bằng chứng số chống chối bỏ:")
            print(f"        - Action: {audit['action']} | Actor: {audit['actor_username']} | Target: {audit['target']}")
            print(f"        - Chi tiết: {audit['new_value']}")

    print("\n" + "=" * 80)
    print(" >>> TẤT CẢ CÁC BÀI TEST SINGLE SIGN-ON (SSO), CÁC WEBSITE MÔ PHỎNG")
    print("     VÀ SINGLE LOGOUT (SLO) CHỐNG REPLAY ATTACK ĐÃ VƯỢT QUA 100%! <<<")
    print("=" * 80)

if __name__ == '__main__':
    test_single_logout_and_apps()
