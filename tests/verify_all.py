import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

import socket
import urllib.request
from radius_client import send_radius_auth

def check_tcp_port(host, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def check_http(url):
    try:
        req = urllib.request.urlopen(url, timeout=3)
        return req.getcode() == 200
    except:
        return False

def run_e2e_verification():
    print("="*75)
    print(" BẢNG KIỂM TRA CHẤT LƯỢNG TOÀN DIỆN HỆ THỐNG NAC (END-TO-END VERIFICATION)")
    print("="*75)
    
    # 1. Health Checks
    print("\n[BƯỚC 1: KIỂM TRA TRẠNG THÁI CÁC CONTAINER DỊCH VỤ]")
    services = [
        ("OpenLDAP Server", "127.0.0.1", 389, "TCP"),
        ("MariaDB Database", "127.0.0.1", 3306, "TCP"),
        ("Flask Dashboard Web", "127.0.0.1", 5000, "TCP"),
    ]
    for name, host, port, proto in services:
        ok = check_tcp_port(host, port)
        status = "\033[92m[ONLINE]\033[0m" if ok else "\033[91m[OFFLINE]\033[0m"
        print(f"  - {name:<22} (Cổng {port:>4}/{proto}): {status}")

    # 2. AAA Authentication & VLAN Tests
    print("\n[BƯỚC 2: KIỂM THỬ XÁC THỰC AAA VÀ GÁN DYNAMIC VLAN (RFC 2868 / 3580)]")
    test_cases = [
        ("Sinh viên (sv_an)", "sv_an", "P@ssword123!", "Access-Accept", "20"),
        ("Giảng viên (gv_nguyen)", "gv_nguyen", "P@ssword123!", "Access-Accept", "30"),
        ("Quản trị (admin01)", "admin01", "P@ssword123!", "Access-Accept", "10"),
        ("Mật khẩu sai", "sv_an", "SaiPassword999", "Access-Reject", None),
        ("User không tồn tại", "user_khong_co", "Pass123", "Access-Reject", None),
    ]

    passed_count = 0
    for title, user, pwd, expected_code, expected_vlan in test_cases:
        res = send_radius_auth('127.0.0.1', 1812, 'testing123', user, pwd)
        code_ok = (res['code_name'] == expected_code)
        vlan_ok = (expected_vlan is None) or (str(res['vlan']) == str(expected_vlan))
        
        if code_ok and vlan_ok:
            passed_count += 1
            mark = "\033[92m[ĐẠT]\033[0m"
        else:
            mark = "\033[91m[HỎNG]\033[0m"
            
        print(f"  {mark} {title:<25} -> Kết quả: {res['code_name']}, VLAN: {res['vlan']} (Kỳ vọng: {expected_code}, VLAN {expected_vlan})")

    # 3. Overall Verdict
    print("\n" + "="*75)
    if passed_count == len(test_cases):
        print(f"\033[92m TẤT CẢ {passed_count}/{len(test_cases)} KỊCH BẢN KIỂM THỬ ĐỀU ĐẠT CHUẨN AN TOÀN VÀ ĐẶC TẢ!\033[0m")
    else:
        print(f"\033[93m ĐẠT {passed_count}/{len(test_cases)} KỊCH BẢN. VUI LÒNG KIỂM TRA LOG DỊCH VỤ.\033[0m")
    print("="*75)

if __name__ == '__main__':
    run_e2e_verification()
