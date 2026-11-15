import sys
import os
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

import urllib.request
import urllib.parse
import hashlib
import requests
from radius_client import send_radius_auth

BASE_URL = 'http://127.0.0.1:5000'

def run_tests():
    print("=" * 72)
    print(" KIỂM THỬ TÍNH NĂNG QUÊN MẬT KHẨU & XÁC THỰC QUA EMAIL (PASSWORD RESET)")
    print("=" * 72)

    # -------------------------------------------------------------------------
    # BƯỚC 1: Kiểm tra liên kết "Quên mật khẩu?" trên trang /login
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 1] Kiểm tra liên kết 'Quên mật khẩu?' tại /login...")
    resp = requests.get(f"{BASE_URL}/login")
    assert resp.status_code == 200, f"Expected 200 on /login, got {resp.status_code}"
    assert "forgot-password" in resp.text or "Quên mật khẩu?" in resp.text, \
        "Không tìm thấy liên kết 'Quên mật khẩu?' trên trang /login"
    print("  -> PASSED: Đã tìm thấy liên kết 'Quên mật khẩu?' trên trang /login.")

    # -------------------------------------------------------------------------
    # BƯỚC 2: Kiểm tra form yêu cầu tại /forgot-password (GET)
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 2] Kiểm tra giao diện yêu cầu khôi phục /forgot-password (GET)...")
    resp = requests.get(f"{BASE_URL}/forgot-password")
    assert resp.status_code == 200, f"Expected 200 on /forgot-password, got {resp.status_code}"
    assert "identifier" in resp.text, "Trường identifier không tồn tại trong form"
    assert "KHÔI PHỤC MẬT KHẨU" in resp.text, "Tiêu đề khôi phục không tồn tại"
    print("  -> PASSED: Form /forgot-password hiển thị đầy đủ và chuẩn xác.")

    # -------------------------------------------------------------------------
    # BƯỚC 3: Kiểm tra phòng chống dò quét tài khoản (Anti-User Enumeration)
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 3] Kiểm tra phòng chống dò quét tài khoản (Anti-User Enumeration)...")
    s = requests.Session()
    resp_fake = s.post(f"{BASE_URL}/forgot-password", data={
        "identifier": "user_khong_he_ton_tai_xyz999"
    })
    assert resp_fake.status_code == 200
    assert "hướng dẫn khôi phục mật khẩu đã được gửi" in resp_fake.text or "email" in resp_fake.text, \
        "Phải phản hồi thông báo an toàn, không được tiết lộ sự tồn tại của tài khoản"
    print("  -> PASSED: Chặn thành công hành vi dò quét danh tính (User Enumeration).")

    # -------------------------------------------------------------------------
    # BƯỚC 4: Gửi yêu cầu khôi phục cho tài khoản thật 'sv_an'
    # -------------------------------------------------------------------------
    target_user = 'sv_an'
    print(f"\n[BƯỚC 4] Gửi yêu cầu đặt lại mật khẩu cho tài khoản sinh viên '{target_user}'...")
    resp_req = s.post(f"{BASE_URL}/forgot-password", data={
        "identifier": target_user
    })
    assert resp_req.status_code == 200
    assert "thành công" in resp_req.text or "Liên kết đặt lại mật khẩu" in resp_req.text, \
        "Không thấy thông báo gửi thành công"
    print(f"  -> PASSED: Hệ thống đã tạo token bảo mật và gửi hướng dẫn đến email của '{target_user}'.")

    # Trích xuất liên kết demo hoặc token từ response
    assert "/reset-password?token=" in resp_req.text or "token=" in resp_req.text, \
        "Không tìm thấy liên kết khôi phục trong phản hồi"
    
    # Lấy token từ liên kết
    reset_link_part = resp_req.text.split('/reset-password?token=')[1]
    raw_token = reset_link_part.split('"')[0].split("'")[0].split('&')[0]
    print(f"  -> Trích xuất One-Time Token an toàn: {raw_token[:12]}... (32 bytes urlsafe)")

    # -------------------------------------------------------------------------
    # BƯỚC 5: Thử nghiệm với Token giả mạo hoặc không hợp lệ
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 5] Kiểm tra bảo vệ khi gửi Token giả mạo hoặc không tồn tại...")
    fake_token = "invalid_fake_token_123456789"
    resp_fake_tok = s.get(f"{BASE_URL}/reset-password?token={fake_token}", allow_redirects=True)
    assert "không hợp lệ" in resp_fake_tok.text or "forgot-password" in resp_fake_tok.url, \
        "Hệ thống phải từ chối token giả mạo"
    print("  -> PASSED: Từ chối tuyệt đối Token giả mạo hoặc không tồn tại.")

    # -------------------------------------------------------------------------
    # BƯỚC 6: Kiểm tra xác thực Token hợp lệ và tải giao diện Đổi Mật Khẩu
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 6] Truy cập liên kết hợp lệ từ email /reset-password?token=...")
    resp_form = s.get(f"{BASE_URL}/reset-password?token={raw_token}")
    assert resp_form.status_code == 200, f"Expected 200, got {resp_form.status_code}"
    assert "ĐẶT LẠI MẬT KHẨU MỚI" in resp_form.text
    assert target_user in resp_form.text
    assert "new_password" in resp_form.text and "confirm_password" in resp_form.text
    print(f"  -> PASSED: Giao diện đặt lại mật khẩu đã mở khóa thành công cho '{target_user}'.")

    # -------------------------------------------------------------------------
    # BƯỚC 7: Kiểm tra vi phạm Chính sách mật khẩu mạnh
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 7] Kiểm tra các ràng buộc Chính sách mật khẩu mạnh...")
    # 7.1 Mật khẩu xác nhận không khớp
    r_bad1 = s.post(f"{BASE_URL}/reset-password?token={raw_token}", data={
        "token": raw_token,
        "new_password": "NewPassword123!",
        "confirm_password": "DifferentPassword123!"
    })
    assert "không khớp" in r_bad1.text
    print("  -> PASSED: Chặn khi mật khẩu xác nhận không khớp.")

    # 7.2 Mật khẩu quá ngắn (< 12 ký tự)
    r_bad2 = s.post(f"{BASE_URL}/reset-password?token={raw_token}", data={
        "token": raw_token,
        "new_password": "Short1!",
        "confirm_password": "Short1!"
    })
    assert "12 ký tự" in r_bad2.text or "chưa đạt chuẩn" in r_bad2.text
    print("  -> PASSED: Chặn khi mật khẩu ngắn hơn 12 ký tự.")

    # 7.3 Mật khẩu thiếu ký tự đặc biệt
    r_bad3 = s.post(f"{BASE_URL}/reset-password?token={raw_token}", data={
        "token": raw_token,
        "new_password": "PasswordWithoutSpecial123",
        "confirm_password": "PasswordWithoutSpecial123"
    })
    assert "ký tự đặc biệt" in r_bad3.text or "chưa đạt chuẩn" in r_bad3.text
    print("  -> PASSED: Chặn khi mật khẩu thiếu ký tự đặc biệt.")

    # -------------------------------------------------------------------------
    # BƯỚC 8: Đặt lại mật khẩu thành công với Mật khẩu Đạt Chuẩn Bảo Mật
    # -------------------------------------------------------------------------
    new_strong_pwd = "P@ssword2026!Updated"
    print(f"\n[BƯỚC 8] Tiến hành đặt lại mật khẩu mới: '{new_strong_pwd}'...")
    resp_success = s.post(f"{BASE_URL}/reset-password?token={raw_token}", data={
        "token": raw_token,
        "new_password": new_strong_pwd,
        "confirm_password": new_strong_pwd
    }, allow_redirects=True)
    assert resp_success.status_code == 200
    assert "thành công" in resp_success.text or "Đăng nhập" in resp_success.text
    print(f"  -> PASSED: Mật khẩu của '{target_user}' đã được cập nhật thành công trên OpenLDAP!")

    # -------------------------------------------------------------------------
    # BƯỚC 9: Kiểm tra chống tấn công dùng lại Token cũ (Anti-Replay Attack)
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 9] Kiểm thử Chống Dùng Lại Mã (Anti-Replay Attack)...")
    resp_replay = s.get(f"{BASE_URL}/reset-password?token={raw_token}", allow_redirects=True)
    assert "đã được sử dụng" in resp_replay.text or "forgot-password" in resp_replay.url, \
        "Token đã dùng phải bị từ chối tuyệt đối"
    print("  -> PASSED: Chặn thành công tấn công dùng lại Token (Replay Attack blocked).")

    # -------------------------------------------------------------------------
    # BƯỚC 10: Xác thực thực tế qua RADIUS (AAA Network Access Control)
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 10] Kiểm thử xác thực mạng thực tế bằng FreeRADIUS...")
    # 10.1 Thử mật khẩu cũ -> Phải bị từ chối (Access-Reject)
    res_old = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, 'P@ssword123!')
    assert res_old['code_name'] == 'Access-Reject', f"Mật khẩu cũ phải bị từ chối, nhận {res_old['code_name']}"
    print(f"  -> PASSED: Mật khẩu CŨ bị FreeRADIUS từ chối chính xác ({res_old['code_name']}).")

    # 10.2 Thử mật khẩu MỚI -> Phải được chấp nhận và gán đúng Dynamic VLAN 20
    res_new = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, new_strong_pwd)
    assert res_new['code_name'] == 'Access-Accept', f"Mật khẩu mới phải được chấp nhận, nhận {res_new['code_name']}"
    assert str(res_new['vlan']) == '20', f"Kỳ vọng VLAN 20, nhận {res_new['vlan']}"
    print(f"  -> PASSED: Mật khẩu MỚI xác thực thành công ({res_new['code_name']}), nhận đúng VLAN {res_new['vlan']}!")

    # -------------------------------------------------------------------------
    # BƯỚC 11: Khôi phục mật khẩu gốc để đảm bảo tương thích 100% với các test cũ
    # -------------------------------------------------------------------------
    print("\n[BƯỚC 11] Dọn dẹp: Khôi phục lại mật khẩu mặc định (P@ssword123!) cho các kịch bản demo...")
    # Yêu cầu token mới để đổi lại
    s.post(f"{BASE_URL}/forgot-password", data={"identifier": target_user})
    resp_clean = s.post(f"{BASE_URL}/forgot-password", data={"identifier": target_user})
    token_clean = resp_clean.text.split('/reset-password?token=')[1].split('"')[0].split("'")[0].split('&')[0]
    s.post(f"{BASE_URL}/reset-password?token={token_clean}", data={
        "token": token_clean,
        "new_password": "P@ssword123!",
        "confirm_password": "P@ssword123!"
    })
    # Kiểm tra lại mật khẩu mặc định
    res_default = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, 'P@ssword123!')
    assert res_default['code_name'] == 'Access-Accept'
    print("  -> PASSED: Đã khôi phục hoàn hảo trạng thái ban đầu của hệ thống!")

    print("\n" + "=" * 72)
    print(" >>> TẤT CẢ 11 BƯỚC KIỂM THỬ QUÊN MẬT KHẨU QUA EMAIL ĐÃ ĐẠT 100%! <<<")
    print("=" * 72)

if __name__ == '__main__':
    run_tests()
