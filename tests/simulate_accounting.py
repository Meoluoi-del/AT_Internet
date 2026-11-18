#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
 CÔNG CỤ MÔ PHỎNG PHIÊN TRUY CẬP MẠNG RADIUS ACCOUNTING (RFC 2866)
 Đề tài: Quản lý truy cập mạng và xác thực trung tâm (NAC)
=============================================================================
Tính năng:
  - demo   : Khởi tạo các phiên trực tuyến mẫu (sv_an, gv_nguyen, admin01) để
             hiển thị trên trang web "Phiên trực tuyến (ACCT)".
  - start  : Bắt đầu 1 phiên kết nối mới (Gửi gói Accounting-Request Start).
  - update : Cập nhật lưu lượng (MB) và thời gian phiên (Interim-Update).
  - stop   : Ngắt kết nối phiên (Gửi gói Accounting-Request Stop).
  - clear  : Đóng toàn bộ các phiên đang mở trên hệ thống.
  - status : Kiểm tra danh sách các phiên đang trực tuyến trong CSDL.
=============================================================================
"""

import sys
import os
import time
import argparse

sys.path.insert(0, os.path.dirname(__file__))
from radius_client import (
    send_radius_acct,
    ACCT_STATUS_START,
    ACCT_STATUS_STOP,
    ACCT_STATUS_INTERIM_UPDATE
)

RADIUS_HOST = os.environ.get("RADIUS_HOST", "127.0.0.1")
RADIUS_ACCT_PORT = int(os.environ.get("RADIUS_ACCT_PORT", "1813"))
RADIUS_SECRET = os.environ.get("RADIUS_SECRET", "testing123")
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")

def get_db():
    import pymysql
    return pymysql.connect(
        host=DB_HOST,
        port=3306,
        user="radius",
        password="RadPassword123!",
        database="radius",
        cursorclass=pymysql.cursors.DictCursor
    )

def do_start(username, ip=None, session_id=None):
    if not session_id:
        session_id = f"NAC-SESS-{username.upper()}-{int(time.time())}"
    if not ip:
        ip = "192.168.20.105" if "sv_" in username else ("192.168.30.105" if "gv_" in username else "192.168.10.105")

    print(f"[*] Đang gửi gói tin Accounting-Request (START) cho '{username}'...")
    print(f"    - Session ID : {session_id}")
    print(f"    - IP cấp phát: {ip}")
    print(f"    - Cổng RADIUS: {RADIUS_HOST}:{RADIUS_ACCT_PORT}/UDP")

    res = send_radius_acct(
        host=RADIUS_HOST,
        port=RADIUS_ACCT_PORT,
        secret=RADIUS_SECRET,
        username=username,
        session_id=session_id,
        status_type=ACCT_STATUS_START,
        framed_ip=ip
    )

    if res['success']:
        print(f"[✓] Thành công! FreeRADIUS đã phản hồi: {res['code_name']}.")
        print(f"[✓] Phiên làm việc của '{username}' hiện ĐANG TRỰC TUYẾN trên Dashboard!")
        return session_id
    else:
        print(f"[✗] Thất bại! Lỗi: {res['code_name']}")
        return None

def do_update(username, session_id, duration_sec=180, in_mb=15.5, out_mb=42.8):
    in_bytes = int(in_mb * 1024 * 1024)
    out_bytes = int(out_mb * 1024 * 1024)
    print(f"[*] Đang cập nhật lưu lượng phiên '{session_id}' cho '{username}' (INTERIM-UPDATE)...")
    print(f"    - Thời gian: {duration_sec} giây | In: {in_mb:.1f} MB | Out: {out_mb:.1f} MB")

    res = send_radius_acct(
        host=RADIUS_HOST,
        port=RADIUS_ACCT_PORT,
        secret=RADIUS_SECRET,
        username=username,
        session_id=session_id,
        status_type=ACCT_STATUS_INTERIM_UPDATE,
        session_time=duration_sec,
        input_octets=in_bytes,
        output_octets=out_bytes
    )

    if res['success']:
        print(f"[✓] Thành công! FreeRADIUS đã cập nhật lưu lượng.")
    else:
        print(f"[✗] Thất bại: {res['code_name']}")

def do_stop(username, session_id, duration_sec=300, in_mb=25.0, out_mb=80.0):
    in_bytes = int(in_mb * 1024 * 1024)
    out_bytes = int(out_mb * 1024 * 1024)
    print(f"[*] Đang ngắt kết nối phiên '{session_id}' cho '{username}' (STOP)...")

    res = send_radius_acct(
        host=RADIUS_HOST,
        port=RADIUS_ACCT_PORT,
        secret=RADIUS_SECRET,
        username=username,
        session_id=session_id,
        status_type=ACCT_STATUS_STOP,
        session_time=duration_sec,
        input_octets=in_bytes,
        output_octets=out_bytes,
        terminate_cause=1
    )

    if res['success']:
        print(f"[✓] Thành công! Phiên kết nối đã đóng lại.")
    else:
        print(f"[✗] Thất bại: {res['code_name']}")

def do_status():
    print("\n" + "=" * 70)
    print(" DANH SÁCH CÁC PHIÊN ĐANG TRỰC TUYẾN TRONG BẢNG RADACCT (MARIADB)")
    print("=" * 70)
    try:
        conn = get_db()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT radacctid, acctsessionid, username, nasipaddress, framedipaddress,
                       acctstarttime, acctsessiontime, acctinputoctets, acctoutputoctets
                FROM radacct
                WHERE acctstoptime IS NULL
                ORDER BY acctstarttime DESC
            """)
            rows = cur.fetchall()
        conn.close()

        if not rows:
            print("  [Thông báo] Hiện không có phiên trực tuyến nào đang mở.")
        else:
            for r in rows:
                in_mb = (r['acctinputoctets'] or 0) / (1024 * 1024)
                out_mb = (r['acctoutputoctets'] or 0) / (1024 * 1024)
                print(f"  • User: {r['username'].ljust(12)} | IP: {r['framedipaddress'].ljust(15)} | Session: {r['acctsessionid']}")
                print(f"    - Bắt đầu lúc: {r['acctstarttime']} | Dung lượng: {in_mb:.2f} MB In / {out_mb:.2f} MB Out")
    except Exception as e:
        print(f"  [Lỗi kết nối CSDL] {e}")
    print("=" * 70 + "\n")

def do_clear():
    print("[*] Đang đóng toàn bộ các phiên trực tuyến trong hệ thống...")
    try:
        conn = get_db()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT username, acctsessionid, framedipaddress 
                FROM radacct 
                WHERE acctstoptime IS NULL
            """)
            active = cur.fetchall()
        conn.close()

        if not active:
            print("[✓] Hiện không có phiên nào đang mở.")
            return

        for s in active:
            do_stop(s['username'], s['acctsessionid'])

        print(f"[✓] Đã đóng thành công {len(active)} phiên trực tuyến!")
    except Exception as e:
        print(f"[✗] Lỗi: {e}")

def do_demo():
    print("\n" + "=" * 70)
    print(" BẮT ĐẦU KHỞI TẠO CÁC PHIÊN TRỰC TUYẾN MẪU (DEMO ACCT SESSIONS)")
    print("=" * 70)

    # 1. Phiên sinh viên sv_an (VLAN 20)
    sess1 = do_start("sv_an", "192.168.20.105")
    time.sleep(0.5)
    if sess1:
        do_update("sv_an", sess1, duration_sec=420, in_mb=12.4, out_mb=35.8)

    # 2. Phiên giảng viên gv_nguyen (VLAN 30)
    sess2 = do_start("gv_nguyen", "192.168.30.102")
    time.sleep(0.5)
    if sess2:
        do_update("gv_nguyen", sess2, duration_sec=1200, in_mb=48.2, out_mb=115.6)

    # 3. Phiên quản trị viên admin01 (VLAN 10)
    sess3 = do_start("admin01", "192.168.10.101")
    time.sleep(0.5)
    if sess3:
        do_update("admin01", sess3, duration_sec=3600, in_mb=105.0, out_mb=250.0)

    print("\n" + "=" * 70)
    print("[✓] ĐÃ KHỞI TẠO THÀNH CÔNG 3 PHIÊN TRỰC TUYẾN MẪU!")
    print("👉 Hãy mở lại trang Web Dashboard tại mục 'PHIÊN TRỰC TUYẾN (ACCT)' để xem kết quả!")
    print("💡 Khi demo xong và muốn dọn sạch, hãy chạy: python tests/simulate_accounting.py clear")
    print("=" * 70 + "\n")

def main():
    parser = argparse.ArgumentParser(description="Mô phỏng phiên truy cập mạng RADIUS Accounting (RFC 2866)")
    subparsers = parser.add_subparsers(dest="cmd")

    subparsers.add_parser("demo", help="Khởi tạo 3 phiên trực tuyến mẫu (sv_an, gv_nguyen, admin01)")
    subparsers.add_parser("status", help="Xem danh sách các phiên trực tuyến hiện tại")
    subparsers.add_parser("clear", help="Đóng tất cả các phiên trực tuyến")

    p_start = subparsers.add_parser("start", help="Bắt đầu 1 phiên kết nối mới")
    p_start.add_argument("username", help="Tên người dùng (vd: sv_an)")
    p_start.add_argument("--ip", default=None, help="Địa chỉ IP cấp phát (vd: 192.168.20.105)")
    p_start.add_argument("--session-id", default=None, help="Mã phiên làm việc tùy chọn")

    p_update = subparsers.add_parser("update", help="Cập nhật lưu lượng phiên")
    p_update.add_argument("username", help="Tên người dùng")
    p_update.add_argument("session_id", help="Mã phiên làm việc")
    p_update.add_argument("--time", type=int, default=180, help="Thời gian kết nối (giây)")
    p_update.add_argument("--in-mb", type=float, default=10.0, help="Dung lượng tải lên (MB)")
    p_update.add_argument("--out-mb", type=float, default=25.0, help="Dung lượng tải xuống (MB)")

    p_stop = subparsers.add_parser("stop", help="Đóng 1 phiên kết nối")
    p_stop.add_argument("username", help="Tên người dùng")
    p_stop.add_argument("session_id", help="Mã phiên làm việc")

    args = parser.parse_args()

    if not args.cmd:
        parser.print_help()
        return

    if args.cmd == "demo":
        do_demo()
    elif args.cmd == "status":
        do_status()
    elif args.cmd == "clear":
        do_clear()
    elif args.cmd == "start":
        do_start(args.username, args.ip, args.session_id)
    elif args.cmd == "update":
        do_update(args.username, args.session_id, args.time, args.in_mb, args.out_mb)
    elif args.cmd == "stop":
        do_stop(args.username, args.session_id)

if __name__ == "__main__":
    main()
