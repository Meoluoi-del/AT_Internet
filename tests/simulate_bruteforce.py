import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

import time
from radius_client import send_radius_auth

def simulate_bruteforce_attack(target_user='sv_test', attempts=6):
    print("="*70)
    print(" KỊCH BẢN TẤN CÔNG BRUTE-FORCE VÀ PHÒNG THỦ CHỦ ĐỘNG (ACTIVE DEFENSE)")
    print("="*70)
    print(f"[*] Mục tiêu tấn công: Tài khoản '{target_user}'")
    print(f"[*] Thực hiện liên tiếp {attempts} lần đăng nhập với mật khẩu sai để kích hoạt cơ chế phòng vệ...")
    
    for i in range(1, attempts + 1):
        fake_pass = f"HackPass_{i}__999"
        res = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, fake_pass)
        print(f"  [Lần {i}/{attempts}] Thử pass: '{fake_pass}' -> Kết quả: \033[91m{res['code_name']}\033[0m")
        time.sleep(1)

    print("\n[+] Đã gửi xong chuỗi tấn công dò mật khẩu!")
    print("[*] Đang chờ Active Defense Detector xử lý (khoảng 10-12 giây)...")
    for sec in range(12, 0, -1):
        print(f"    Chờ phát hiện: {sec}s...", end="\r")
        time.sleep(1)
    print("\n[+] Hệ thống đã hoàn tất chu kỳ quét và tự động cô lập tài khoản!")

    print("\n[*] Bây giờ, kẻ tấn công (hoặc người dùng) nhập lại với MẬT KHẨU ĐÚNG ('P@ssword123!')...")
    res_correct = send_radius_auth('127.0.0.1', 1812, 'testing123', target_user, 'P@ssword123!')
    
    print(f"  --> Trạng thái: \033[92m{res_correct['code_name']}\033[0m (Mật khẩu đúng)")
    print(f"  --> Phân đoạn mạng nhận được: \033[91mVLAN {res_correct['vlan']} (QUARANTINE / CÁCH LY)\033[0m")
    
    if str(res_correct['vlan']) == '99':
        print("\n\033[92m[THÀNH CÔNG] Cơ chế Active Defense hoạt động chính xác! Người dùng đã bị tước quyền mạng thông thường và giam giữ tại VLAN 99!\033[0m")
    else:
        print(f"\n\033[93m[LƯU Ý] Nhận VLAN {res_correct['vlan']}, kiểm tra trạng thái nhóm trên Web Dashboard.\033[0m")

if __name__ == '__main__':
    user = sys.argv[1] if len(sys.argv) > 1 else 'sv_test'
    simulate_bruteforce_attack(user)
