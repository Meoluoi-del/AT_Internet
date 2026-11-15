#!/usr/bin/env python3
"""
Test Suite: Kiểm thử Tính năng Tự đăng ký tài khoản (Self-Registration) & SSO Integration.
========================================================================================
1. Kiểm tra giao diện GET /register và liên kết trên /login.
2. Kiểm tra các ràng buộc bảo mật:
   - Mật khẩu xác nhận không khớp.
   - Tên đăng nhập cấm / quản trị (admin, auditor, root,...).
   - Nhóm quyền cấm (quantri, quarantine,...).
   - Trùng lặp username với tài khoản đã tồn tại.
3. Đăng ký thành công tài khoản Sinh viên (VLAN 20) và Giảng viên (VLAN 30).
4. Kiểm tra tài khoản tự tạo có thể đăng nhập ngay, cấp Master Session và truy cập Cổng SSO.
5. Dọn dẹp tài khoản kiểm thử khỏi OpenLDAP.
"""

import sys
import os
import urllib.request
import urllib.parse
import http.cookiejar
import json
import re

os.environ['LDAP_HOST'] = '127.0.0.1'
os.environ['DB_HOST'] = '127.0.0.1'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'dashboard'))

BASE_URL = "http://localhost:5000"

def get_session():
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    return opener

def test_registration_flow():
    print("=" * 70)
    print("BẮT ĐẦU TEST TÍNH NĂNG TỰ ĐĂNG KÝ TÀI KHOẢN (SELF-REGISTRATION)")
    print("=" * 70)

    # 1. Kiểm tra /login có chứa liên kết tự đăng ký
    print("\n[BƯỚC 1] Kiểm tra liên kết đăng ký tại /login...")
    opener = get_session()
    resp = opener.open(f"{BASE_URL}/login")
    login_html = resp.read().decode('utf-8')
    assert "Tự đăng ký ngay" in login_html or "/register" in login_html, "Không tìm thấy nút/liên kết Đăng ký tại /login"
    print("  -> PASSED: Đã tìm thấy liên kết 'Tự đăng ký ngay' trên trang /login.")

    # Dọn dẹp trước phòng trường hợp test user còn tồn tại từ trước
    from ldap_client import LDAPClient
    ldap = LDAPClient()
    for u in ["sv_tuananh", "gv_huong", "sv_test_invalid", "sv_fake_admin"]:
        try:
            if ldap.user_exists(u):
                ldap.delete_user(u)
        except Exception:
            pass

    # 2. Kiểm tra trang /register (GET)
    print("\n[BƯỚC 2] Kiểm tra form đăng ký tại /register (GET)...")
    resp = opener.open(f"{BASE_URL}/register")
    reg_url = resp.geturl()
    m_sid = re.search(r'sid=([a-f0-9]+)', reg_url)
    current_sid = m_sid.group(1) if m_sid else ''
    reg_html = resp.read().decode('utf-8')
    assert resp.status == 200
    assert 'name="uid"' in reg_html
    assert 'name="cn"' in reg_html
    assert 'name="mail"' in reg_html
    assert 'name="group"' in reg_html
    assert 'name="password"' in reg_html
    assert 'name="confirm_password"' in reg_html
    print(f"  -> PASSED: Form đăng ký hiển thị đầy đủ các trường thông tin (sid={current_sid}).")

    # 3. Kiểm tra các ràng buộc bảo mật (Validation)
    print("\n[BƯỚC 3] Kiểm tra các ràng buộc bảo mật đầu vào...")

    # 3.1 Mật khẩu không khớp
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_test_invalid',
        'cn': 'Nguyễn Văn Test',
        'mail': 'test@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'Password123!',
        'confirm_password': 'DifferentPassword!'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "không khớp" in html, "Không bắt được lỗi mật khẩu xác nhận không khớp"
    print("  -> PASSED: Chặn thành công khi mật khẩu xác nhận không khớp.")

    # 3.2 Tên đăng nhập quản trị dành riêng (admin)
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'admin',
        'cn': 'Hacker Muốn Làm Admin',
        'mail': 'hacker@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'Password123!',
        'confirm_password': 'Password123!'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "dành riêng" in html or "quản trị" in html or "tồn tại" in html, "Không chặn username admin"
    print("  -> PASSED: Chặn thành công hành vi cố tình đăng ký tên 'admin'.")

    # 3.3 Nhóm cấm (quantri)
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_fake_admin',
        'cn': 'Fake Admin',
        'mail': 'fake@ptit.edu.vn',
        'group': 'quantri',
        'password': 'Password123!',
        'confirm_password': 'Password123!'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "không hợp lệ" in html or "Chỉ được phép" in html, "Không chặn group quantri"
    print("  -> PASSED: Chặn thành công hành vi cố tình tự đăng ký nhóm 'quantri'.")

    # 3.4 Username đã tồn tại (sv_vinh)
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_vinh',
        'cn': 'Nguyễn Văn Vinh Fake',
        'mail': 'vinh.fake@gmail.com',
        'group': 'sinhvien',
        'password': 'Password123!@#',
        'confirm_password': 'Password123!@#'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "đã tồn tại" in html, "Không báo lỗi tài khoản đã tồn tại"
    print("  -> PASSED: Chặn thành công khi đăng ký trùng username đã có ('sv_vinh').")

    # 3.5 Chính sách mật khẩu: Dưới 12 ký tự
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_short_pass',
        'cn': 'Nguyễn Văn Ngắn',
        'mail': 'short@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'Pass123!Abc', # 11 ký tự (< 12)
        'confirm_password': 'Pass123!Abc'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "Tối thiểu 12 ký tự" in html, "Không bắt được lỗi mật khẩu dưới 12 ký tự"
    print("  -> PASSED: Chặn thành công mật khẩu ngắn dưới 12 ký tự.")

    # 3.6 Chính sách mật khẩu: Thiếu chữ in hoa (A-Z)
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_no_upper',
        'cn': 'Nguyễn Văn Thường',
        'mail': 'noupper@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'nouppercase123!@#', # Không có in hoa
        'confirm_password': 'nouppercase123!@#'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "in hoa" in html, "Không bắt được lỗi mật khẩu thiếu chữ in hoa"
    print("  -> PASSED: Chặn thành công mật khẩu thiếu chữ in hoa (A-Z).")

    # 3.7 Chính sách mật khẩu: Thiếu chữ số (0-9)
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_no_digit',
        'cn': 'Nguyễn Văn Chữ',
        'mail': 'nodigit@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'NoDigitPassword!@#', # Không có số
        'confirm_password': 'NoDigitPassword!@#'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "chữ số" in html, "Không bắt được lỗi mật khẩu thiếu chữ số"
    print("  -> PASSED: Chặn thành công mật khẩu thiếu chữ số (0-9).")

    # 3.8 Chính sách mật khẩu: Thiếu ký tự đặc biệt
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': 'sv_no_special',
        'cn': 'Nguyễn Văn Đơn Giản',
        'mail': 'nospecial@ptit.edu.vn',
        'group': 'sinhvien',
        'password': 'NoSpecialPassword123456', # Không có ký tự đặc biệt
        'confirm_password': 'NoSpecialPassword123456'
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "ký tự đặc biệt" in html, "Không bắt được lỗi mật khẩu thiếu ký tự đặc biệt"
    print("  -> PASSED: Chặn thành công mật khẩu thiếu ký tự đặc biệt.")

    # 4. Tự đăng ký Sinh viên mới (VLAN 20)
    print("\n[BƯỚC 4] Đăng ký thành công tài khoản Sinh viên mới: sv_tuananh...")
    test_user_sv = "sv_tuananh"
    test_pass_sv = "TuanAnhPass123!"
    data = urllib.parse.urlencode({
        'sid': current_sid,
        'uid': test_user_sv,
        'cn': 'Lê Tuấn Anh',
        'mail': 'tuananh.le@ptit.edu.vn',
        'group': 'sinhvien',
        'password': test_pass_sv,
        'confirm_password': test_pass_sv
    }).encode('utf-8')
    resp = opener.open(f"{BASE_URL}/register", data=data)
    html = resp.read().decode('utf-8')
    assert "thành công" in html, f"Đăng ký {test_user_sv} thất bại: {html[:300]}"
    print(f"  -> PASSED: Đăng ký thành công tài khoản {test_user_sv}!")

    # 5. Kiểm tra đăng nhập với tài khoản sinh viên vừa đăng ký
    print("\n[BƯỚC 5] Đăng nhập Cổng SSO bằng tài khoản sinh viên vừa tạo...")
    sv_opener = get_session()
    r_login = sv_opener.open(f"{BASE_URL}/login")
    m_sv_sid = re.search(r'sid=([a-f0-9]+)', r_login.geturl())
    sv_sid = m_sv_sid.group(1) if m_sv_sid else ''
    login_data = urllib.parse.urlencode({
        'sid': sv_sid,
        'username': test_user_sv,
        'password': test_pass_sv
    }).encode('utf-8')
    resp = sv_opener.open(f"{BASE_URL}/login?sid={sv_sid}", data=login_data)
    sso_html = resp.read().decode('utf-8')
    assert "CỔNG SINGLE SIGN-ON" in sso_html or "Lê Tuấn Anh" in sso_html, "Không vào được Cổng SSO"
    assert "VLAN 20" in sso_html, "Không nhận đúng phân đoạn VLAN 20"
    print(f"  -> PASSED: Tài khoản {test_user_sv} đăng nhập thành công vào Cổng SSO (Nhận VLAN 20 - sinhvien)!")

    # 6. Kiểm tra truy cập ứng dụng SSO (QLĐT / LMS)
    print("\n[BƯỚC 6] Kiểm tra tài khoản tự tạo truy cập 1-chạm vào QLĐT / LMS...")
    resp = sv_opener.open(f"{BASE_URL}/apps/qldt?sid={sv_sid}")
    qldt_html = resp.read().decode('utf-8')
    assert "CỔNG ĐÀO TẠO & QUẢN LÝ HỌC TẬP" in qldt_html or "Lê Tuấn Anh" in qldt_html
    print("  -> PASSED: Sinh viên tự tạo truy cập ứng dụng QLĐT mượt mà không cần nhập lại pass!")

    # 7. Tự đăng ký Giảng viên mới (VLAN 30)
    print("\n[BƯỚC 7] Đăng ký thành công tài khoản Giảng viên mới: gv_huong...")
    test_user_gv = "gv_huong"
    test_pass_gv = "HuongPass123!"
    gv_reg_opener = get_session()
    r_gv_reg = gv_reg_opener.open(f"{BASE_URL}/register")
    m_gv_reg_sid = re.search(r'sid=([a-f0-9]+)', r_gv_reg.geturl())
    gv_reg_sid = m_gv_reg_sid.group(1) if m_gv_reg_sid else ''
    data_gv = urllib.parse.urlencode({
        'sid': gv_reg_sid,
        'uid': test_user_gv,
        'cn': 'Trần Thu Hương',
        'mail': 'huong.tt@ptit.edu.vn',
        'group': 'giangvien',
        'password': test_pass_gv,
        'confirm_password': test_pass_gv
    }).encode('utf-8')
    resp = gv_reg_opener.open(f"{BASE_URL}/register?sid={gv_reg_sid}", data=data_gv)
    html = resp.read().decode('utf-8')
    assert "thành công" in html, f"Đăng ký {test_user_gv} thất bại"
    print(f"  -> PASSED: Đăng ký thành công Giảng viên {test_user_gv}!")

    # 8. Kiểm tra đăng nhập với tài khoản giảng viên
    print("\n[BƯỚC 8] Đăng nhập Cổng SSO bằng tài khoản giảng viên vừa tạo...")
    gv_opener = get_session()
    r_gv_login = gv_opener.open(f"{BASE_URL}/login")
    m_gv_sid = re.search(r'sid=([a-f0-9]+)', r_gv_login.geturl())
    gv_sid = m_gv_sid.group(1) if m_gv_sid else ''
    login_data_gv = urllib.parse.urlencode({
        'sid': gv_sid,
        'username': test_user_gv,
        'password': test_pass_gv
    }).encode('utf-8')
    resp = gv_opener.open(f"{BASE_URL}/login?sid={gv_sid}", data=login_data_gv)
    sso_gv_html = resp.read().decode('utf-8')
    assert "Trần Thu Hương" in sso_gv_html
    assert "VLAN 30" in sso_gv_html or "giangvien" in sso_gv_html
    print(f"  -> PASSED: Giảng viên {test_user_gv} đăng nhập thành công vào Cổng SSO (Nhận VLAN 30 - giangvien)!")

    # 9. Dọn dẹp tài khoản kiểm thử
    print("\n[BƯỚC 9] Dọn dẹp dữ liệu tài khoản test khỏi OpenLDAP...")
    from ldap_client import LDAPClient
    ldap = LDAPClient()
    for u in [test_user_sv, test_user_gv]:
        try:
            if ldap.user_exists(u):
                ldap.delete_user(u)
                print(f"  -> Đã xóa tài khoản tạm '{u}' khỏi OpenLDAP.")
        except Exception as e:
            print(f"  -> Lưu ý khi xóa {u}: {e}")

    print("\n" + "=" * 70)
    print("TẤT CẢ CÁC BƯỚC TEST TỰ ĐĂNG KÝ TÀI KHOẢN ĐÃ HOÀN TẤT VÀ ĐẠT 100%!")
    print("=" * 70)

if __name__ == "__main__":
    test_registration_flow()
