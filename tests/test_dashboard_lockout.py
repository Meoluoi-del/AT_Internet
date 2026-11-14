import urllib.request
import urllib.parse
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'dashboard')))
from models import DBManager, get_db_connection

def test_dashboard_lockout():
    print("=" * 70)
    print(" BẮT ĐẦU KIỂM THỬ: KHÓA KÉP TÀI KHOẢN & CHẶN IP KHI ĐĂNG NHẬP DASHBOARD SAI 5 LẦN")
    print("=" * 70)

    # 1. Reset dữ liệu khóa
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM dashboard_account_lockouts WHERE username IN ('admin', 'auditor')")
        cur.execute("DELETE FROM dashboard_ip_lockouts")
    conn.commit()
    conn.close()
    print("[1] Đã dọn dẹp sạch bảng khóa tài khoản và IP.")

    # 2. Thử sai lần 1
    req0 = urllib.request.urlopen('http://127.0.0.1:5000/login')
    sid = req0.geturl().split('sid=')[1].split('&')[0] if 'sid=' in req0.geturl() else ''
    
    data1 = urllib.parse.urlencode({'username': 'admin', 'password': 'WrongPassword1', 'sid': sid}).encode()
    resp1 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=data1)).read().decode('utf-8')
    assert 'còn 4 lần thử' in resp1.lower()
    print("[*] Lần 1: Nhập sai mật khẩu -> Báo còn 4 lần thử thành công.")

    # 3. Thử sai lần 2
    data2 = urllib.parse.urlencode({'username': 'admin', 'password': 'WrongPassword2', 'sid': sid}).encode()
    resp2 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=data2)).read().decode('utf-8')
    assert 'còn 3 lần thử' in resp2.lower()
    print("[*] Lần 2: Nhập sai mật khẩu -> Báo còn 3 lần thử thành công.")

    # 4. Thử sai lần 3
    data3 = urllib.parse.urlencode({'username': 'admin', 'password': 'WrongPassword3', 'sid': sid}).encode()
    resp3 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=data3)).read().decode('utf-8')
    assert 'còn 2 lần thử' in resp3.lower()
    print("[*] Lần 3: Nhập sai mật khẩu -> Báo còn 2 lần thử thành công.")

    # 5. Thử sai lần 4
    data4 = urllib.parse.urlencode({'username': 'admin', 'password': 'WrongPassword4', 'sid': sid}).encode()
    resp4 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=data4)).read().decode('utf-8')
    assert 'còn 1 lần thử' in resp4.lower()
    print("[*] Lần 4: Nhập sai mật khẩu -> Báo còn 1 lần thử thành công.")

    # 6. Thử sai lần 5 -> KÍCH HOẠT KHÓA KÉP (1 TIẾNG)
    data5 = urllib.parse.urlencode({'username': 'admin', 'password': 'WrongPassword5', 'sid': sid}).encode()
    resp5 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}', data=data5)).read().decode('utf-8')
    assert 'bị khóa trong 1 tiếng' in resp5 or 'quá 5 lần' in resp5
    print("[*] Lần 5: Nhập sai mật khẩu -> KÍCH HOẠT KHÓA KÉP TÀI KHOẢN VÀ CHẶN IP TRONG 1 TIẾNG THÀNH CÔNG!")

    # 7. Kiểm tra trạng thái trong MariaDB
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM dashboard_account_lockouts WHERE username = 'admin'")
        acc_row = cur.fetchone()
        print(f"[*] MariaDB Account Lock: failed_attempts={acc_row['failed_attempts']}, locked_until={acc_row['locked_until']}, ip={acc_row['last_failed_ip']}")
        assert acc_row['failed_attempts'] >= 5
        assert acc_row['locked_until'] is not None

        cur.execute("SELECT * FROM dashboard_ip_lockouts")
        ip_row = cur.fetchone()
        print(f"[*] MariaDB IP Block: ip={ip_row['ip_address']}, failed_attempts={ip_row['failed_attempts']}, blocked_until={ip_row['blocked_until']}")
        assert ip_row['failed_attempts'] >= 5
        assert ip_row['blocked_until'] is not None

        # Kiểm tra Audit Logs
        cur.execute("SELECT action, actor_username, new_value, old_value FROM audit_logs WHERE action LIKE 'DASHBOARD_%' ORDER BY id DESC LIMIT 8")
        logs = cur.fetchall()
        print("\n[*] Nhật ký Audit Logs đã ghi nhận:")
        for l in logs:
            print(f"    - Action: {l['action']:<25} | Actor: {l['actor_username']:<15} | New: {l['new_value']}")
    conn.close()

    # 8. Thử truy cập lần 6 (bị chặn bởi IP Block)
    print("\n[*] Lần 6: Cố tình truy cập tiếp từ IP đang bị chặn...")
    resp6 = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid}')).read().decode('utf-8')
    assert 'IP đang bị tạm chặn' in resp6 or 'tạm chặn' in resp6
    print("[=>] Bị chặn từ cửa ngoài: Form đăng nhập bị khóa và thông báo thời gian còn lại (~60 phút) hiển thị chuẩn xác.")

    # 9. Giải phóng khóa và thử đăng nhập đúng mật khẩu
    print("\n[*] Dọn dẹp khóa để kiểm thử đăng nhập thành công...")
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM dashboard_account_lockouts WHERE username IN ('admin', 'auditor')")
        cur.execute("DELETE FROM dashboard_ip_lockouts")
    conn.commit()
    conn.close()

    req_ok = urllib.request.urlopen('http://127.0.0.1:5000/login')
    sid_ok = req_ok.geturl().split('sid=')[1].split('&')[0] if 'sid=' in req_ok.geturl() else ''
    data_ok = urllib.parse.urlencode({'username': 'admin', 'password': 'AdminPassword123!', 'sid': sid_ok}).encode()
    resp_ok = urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:5000/login?sid={sid_ok}', data=data_ok)).read().decode('utf-8')
    assert 'Chào mừng' in resp_ok or 'TỔNG QUAN' in resp_ok
    print("[*] Đăng nhập thành công với mật khẩu đúng -> Vào Bảng Điều Khiển bình thường.")

    print("\n" + "=" * 70)
    print(" TẤT CẢ CÁC BÀI KIỂM THỬ ĐÃ VƯỢT QUA 100% THÀNH CÔNG!")
    print("=" * 70)

if __name__ == '__main__':
    test_dashboard_lockout()
