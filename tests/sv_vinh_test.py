import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

import time
from radius_client import send_radius_auth

def simulate_bruteforce_attack(target_user='sv_vinh', attempts=1000):
    print("="*70)
    print(" KỊCH BẢN TẤN CÔNG BRUTE-FORCE VÀ PHÒNG THỦ CHỦ ĐỘNG (ACTIVE DEFENSE)")
    print("="*70)
    print(f"[*] Mục tiêu tấn công: Tài khoản '{target_user}'")
    print(f"[*] Thực hiện liên tiếp {attempts} lần đăng nhập với mật khẩu sai để kích hoạt cơ chế phòng vệ...")
    
    found_success = False

    for i in range(120, attempts + 1):
        fake_pass = f"{i}"
        res = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, fake_pass)
        
        # Khi thử đúng mật khẩu -> Dừng lại và gửi request xác thực mật khẩu đúng
        if res.get('code_name') == 'Access-Accept':
            found_success = True
            print(f"  --> \033[92m[Lần {i}/{attempts}] Thử pass: '{fake_pass}' -> ĐĂNG NHẬP THÀNH CÔNG (Mật khẩu đúng)!\033[0m")
            print(f"[*] Đã tìm thấy mật khẩu chính xác là: '{fake_pass}'. Dừng vòng lặp để tránh tốn tài nguyên!")
            
            print(f"\n[*] Gửi request xác thực với mật khẩu đúng '{fake_pass}'...")
            res_correct = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, fake_pass)
            print(f"  --> Trạng thái: \033[92m{res_correct['code_name']}\033[0m (Đăng nhập thành công)")
            vlan = res_correct.get('vlan')
            if str(vlan) == '99':
                print(f"  --> Phân đoạn mạng nhận được: \033[91mVLAN {vlan} (QUARANTINE / CÁCH LY)\033[0m")
                print("  --> [PHÒNG VỆ CHỦ ĐỘNG]: Tài khoản đã bị cô lập sang VLAN 99 do thử sai quá 6 lần trước đó!")
            else:
                print(f"  --> Phân đoạn mạng nhận được: \033[92mVLAN {vlan}\033[0m")
            break

        print(f"  [Lần {i}/{attempts}] Thử pass: '{fake_pass}' -> Kết quả: \033[91m{res['code_name']}\033[0m")
        time.sleep(1)

    if not found_success:
        print("\n[+] Đã gửi xong chuỗi tấn công dò mật khẩu!")
        print("[*] Đang chờ Active Defense Detector xử lý (khoảng 6-8 giây)...")
        for sec in range(8, 0, -1):
            print(f"    Chờ phát hiện: {sec}s...", end="\r")
            time.sleep(1)
        print("\n[+] Hệ thống đã hoàn tất chu kỳ quét! Kiểm tra trạng thái cô lập tài khoản trên Web Dashboard.")

if __name__ == '__main__':
    user = sys.argv[1] if len(sys.argv) > 1 else 'sv_vinh'
    attempts = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    simulate_bruteforce_attack(user, attempts)
