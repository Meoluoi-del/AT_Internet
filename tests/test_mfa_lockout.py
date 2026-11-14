import urllib.request
import urllib.parse
import json
import time
import os
import sys

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'dashboard')))

from mfa import generate_secret, get_totp_code
from models import DBManager, get_db_connection

def test_mfa_security():
    print("=" * 70)
    print(" BẮT ĐẦU KIỂM THỬ: GIỚI HẠN SAI OTP VÀ CHỐNG DÙNG LẠI MÃ (MFA)")
    print("=" * 70)

    # 1. Cài đặt tài khoản admin với MFA và trạng thái sạch
    secret = 'JBSWY3DPEHPK3PXP'  # Base32 secret chuẩn
    DBManager.save_user_mfa('admin', secret, is_enabled=1)
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("UPDATE user_mfa SET failed_otp_attempts = 0, otp_locked_until = NULL, last_verified_step = NULL WHERE username = 'admin'")
    conn.close()
    print("[1] Đã khởi tạo trạng thái sạch cho tài khoản 'admin' với MFA kích hoạt.")

    # 2. Đăng nhập Bước 1: user + pass
    req0 = urllib.request.urlopen('http://127.0.0.1:5000/login')
    login_url = req0.geturl()
    sid = login_url.split('sid=')[1].split('&')[0] if 'sid=' in login_url else ''

    login_data = urllib.parse.urlencode({'username': 'admin', 'password': 'AdminPassword123!', 'sid': sid}).encode()
    req1 = urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=login_data)
    resp1 = urllib.request.urlopen(req1)
    print("[2] Bước 1 (Mật khẩu đúng) -> Chuyển hướng sang MFA Step 2 thành công.")

    # 3. Test mã OTP hợp lệ
    current_otp = get_totp_code(secret)
    print(f"[*] Mã OTP hợp lệ sinh ra: {current_otp}")
    mfa_data = urllib.parse.urlencode({'code': current_otp, 'sid': sid}).encode()
    req2 = urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid}', data=mfa_data)
    resp2 = urllib.request.urlopen(req2)
    content2 = resp2.read().decode('utf-8')
    assert 'Chào mừng' in content2 or 'TỔNG QUAN' in content2 or resp2.geturl().endswith(':5000/') or 'sid=' in resp2.geturl()
    print("[3] Xác thực OTP thành công lần đầu.")

    # Kiểm tra database đã ghi nhận last_verified_step
    mfa_row = DBManager.get_user_mfa('admin')
    print(f"[*] Database đã ghi nhận last_verified_step = {mfa_row['last_verified_step']}")
    assert mfa_row['last_verified_step'] is not None

    # 4. TEST CHỐNG DÙNG LẠI MÃ (ANTI-REPLAY ATTACK):
    # Tạo phiên đăng nhập mới và thử gửi lại CHÍNH MÃ current_otp vừa dùng
    print("\n--- TEST 1: CHỐNG DÙNG LẠI MÃ OTP (REPLAY ATTACK) ---")
    req3 = urllib.request.urlopen('http://127.0.0.1:5000/login')
    sid2 = req3.geturl().split('sid=')[1].split('&')[0]
    login_data2 = urllib.parse.urlencode({'username': 'admin', 'password': 'AdminPassword123!', 'sid': sid2}).encode()
    urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid2}', data=login_data2))

    # Gửi lại mã current_otp (Replay)
    req4 = urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid2}', data=mfa_data)
    resp4 = urllib.request.urlopen(req4)
    content4 = resp4.read().decode('utf-8')
    is_replay_blocked = 'đã được sử dụng' in content4
    print(f"[*] Gửi lại mã OTP '{current_otp}' trong cùng chu kỳ 30s...")
    print(f"[=>] Kết quả: {'BỊ CHẶN CHÍNH XÁC (Mã đã được sử dụng)' if is_replay_blocked else 'THẤT BẠI'}")
    assert is_replay_blocked, "Lỗi: Không chặn được Replay Attack!"

    # 5. TEST GIỚI HẠN NHẬP SAI QUÁ 3 LẦN -> KHÓA 10 PHÚT
    print("\n--- TEST 2: GIỚI HẠN NHẬP SAI OTP (LOCKOUT 10 PHÚT KHI SAI 3 LẦN) ---")
    
    # Lần 1: Sai
    fail_data1 = urllib.parse.urlencode({'code': '000000', 'sid': sid2}).encode()
    resp_f1 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid2}', data=fail_data1)).read().decode('utf-8')
    assert 'Còn 2 lần thử' in resp_f1 or '2 lần thử' in resp_f1
    print("[*] Lần 1 (Nhập sai 000000) -> Cảnh báo còn 2 lần thử.")

    # Lần 2: Sai
    fail_data2 = urllib.parse.urlencode({'code': '111111', 'sid': sid2}).encode()
    resp_f2 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid2}', data=fail_data2)).read().decode('utf-8')
    assert 'Còn 1 lần thử' in resp_f2 or '1 lần thử' in resp_f2
    print("[*] Lần 2 (Nhập sai 111111) -> Cảnh báo còn 1 lần thử.")

    # Lần 3: Sai -> Kích hoạt khóa 10 phút!
    fail_data3 = urllib.parse.urlencode({'code': '222222', 'sid': sid2}).encode()
    resp_f3 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid2}', data=fail_data3)).read().decode('utf-8')
    assert '10 phút' in resp_f3 or 'tạm khóa' in resp_f3
    print("[*] Lần 3 (Nhập sai 222222) -> TÀI KHOẢN ĐÃ BỊ KHÓA 10 PHÚT!")

    # Lần 4: Thử nhập lại khi đang bị khóa
    print("\n[*] Lần 4 (Cố tình nhập tiếp khi đang bị khóa)...")
    resp_f4 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/mfa/verify?sid={sid2}', data=fail_data3)).read().decode('utf-8')
    assert 'tạm khóa' in resp_f4
    print("[=>] Bị từ chối ngay lập tức, hiển thị giao diện khóa với thời gian còn lại.")

    # Kiểm tra database xác nhận trạng thái khóa
    mfa_locked = DBManager.get_user_mfa('admin')
    print(f"[*] Trạng thái MariaDB: failed_otp_attempts = {mfa_locked['failed_otp_attempts']}, otp_locked_until = {mfa_locked['otp_locked_until']}")
    assert mfa_locked['failed_otp_attempts'] >= 3
    assert mfa_locked['otp_locked_until'] is not None

    # Kiểm tra Audit Logs
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("SELECT action, new_value, old_value FROM audit_logs WHERE actor_username = 'admin' ORDER BY id DESC LIMIT 5")
        logs = cur.fetchall()
        print("\n[*] Nhật ký Audit Logs gần nhất:")
        for log in logs:
            print(f"    - Action: {log['action']} | New: {log['new_value']} | Old: {log['old_value']}")
    conn.close()

    print("\n" + "=" * 70)
    print(" TẤT CẢ CÁC BÀI KIỂM THỬ ĐÃ VƯỢT QUA 100% THÀNH CÔNG!")
    print("=" * 70)

if __name__ == '__main__':
    test_mfa_security()
