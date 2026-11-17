#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
 BỘ CÔNG CỤ ĐỒNG BỘ CƠ SỞ DỮ LIỆU QUA GIT (GIT DATABASE SYNC TOOL)
 Đề tài: Quản lý truy cập mạng & Xác thực tập trung (NAC & IAM)
 Sinh viên: Học viện Công nghệ Bưu chính Viễn thông (PTIT)
=============================================================================
Tính năng:
  - export: Trích xuất trạng thái mới nhất từ MariaDB và OpenLDAP vào thư mục
            `data_sync/` và `ldap/init-ldap.ldif` trước khi đẩy lên Git.
  - import: Tự động nạp dữ liệu snapshot từ Git vào các container đang chạy
            trên máy khác sau khi `git pull`.
  - status: Xem trạng thái các container và dữ liệu đồng bộ.
  - install-hooks: Tự động cài Git Hooks (pre-commit & post-merge) để đồng bộ 
                   hoàn toàn tự động mỗi khi commit và pull!
=============================================================================
"""

import sys
import os
import subprocess
import shutil
import time

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))
DATA_SYNC_DIR = os.path.join(PROJECT_ROOT, "data_sync")
MARIADB_DUMP_FILE = os.path.join(DATA_SYNC_DIR, "mariadb_snapshot.sql")
LDAP_DUMP_FILE = os.path.join(DATA_SYNC_DIR, "ldap_snapshot.ldif")
INIT_LDAP_FILE = os.path.join(PROJECT_ROOT, "ldap", "init-ldap.ldif")
SQL_INIT_FILE = os.path.join(PROJECT_ROOT, "sql", "init-policy.sql")

def log(msg, level="INFO"):
    colors = {
        "INFO": "\033[94m[*]\033[0m",
        "SUCCESS": "\033[92m[✓]\033[0m",
        "WARN": "\033[93m[!]\033[0m",
        "ERROR": "\033[91m[✗]\033[0m",
    }
    # Windows terminal color fallback
    tag = colors.get(level, f"[{level}]")
    print(f"{tag} {msg}")

def run_cmd(cmd, input_data=None, capture=True, check=True):
    """Thực thi lệnh shell / subprocess an toàn đa nền tảng"""
    try:
        proc = subprocess.run(
            cmd,
            input=input_data,
            capture_output=capture,
            check=check,
            cwd=PROJECT_ROOT
        )
        return proc
    except subprocess.CalledProcessError as e:
        stderr = e.stderr.decode('utf-8', errors='replace') if e.stderr else str(e)
        stdout = e.stdout.decode('utf-8', errors='replace') if e.stdout else ""
        raise RuntimeError(f"Lỗi khi chạy lệnh: {' '.join(cmd)}\nChi tiết: {stderr} {stdout}")

def check_container_running(name):
    """Kiểm tra container Docker có đang chạy không"""
    try:
        res = run_cmd(["docker", "ps", "--filter", f"name={name}", "--format", "{{.Names}}"])
        return name in res.stdout.decode('utf-8')
    except Exception:
        return False

def ensure_containers_up():
    """Đảm bảo các container MariaDB và LDAP đang hoạt động"""
    if not check_container_running("nac_mariadb") or not check_container_running("nac_ldap"):
        log("Các container cơ sở dữ liệu chưa chạy. Đang khởi động qua Docker Compose...", "WARN")
        run_cmd(["docker", "compose", "up", "-d", "nac_mariadb", "nac_ldap", "nac_radius", "nac_dashboard"])
        time.sleep(3)

def export_mariadb():
    """Xuất snapshot MariaDB hoàn chỉnh (bảng, dữ liệu, triggers, views)"""
    log("Đang trích xuất dữ liệu MariaDB (nac_mariadb)...")
    cmd = [
        "docker", "exec", "nac_mariadb",
        "mariadb-dump", "-u", "root", "-pRootPassword123!",
        "--single-transaction", "--quick", "--routines", "--triggers",
        "--default-character-set=utf8mb4",
        "--databases", "radius"
    ]
    proc = run_cmd(cmd)
    sql_data = proc.stdout

    os.makedirs(DATA_SYNC_DIR, exist_ok=True)
    with open(MARIADB_DUMP_FILE, "wb") as f:
        f.write(sql_data)

    size_kb = len(sql_data) / 1024
    log(f"Đã lưu MariaDB snapshot vào {os.path.relpath(MARIADB_DUMP_FILE)} ({size_kb:.1f} KB)", "SUCCESS")

def export_ldap():
    """Xuất snapshot OpenLDAP hoàn chỉnh (tài khoản, nhóm quyền, OU, dịch vụ)"""
    log("Đang trích xuất cây thư mục OpenLDAP (nac_ldap)...")
    cmd = [
        "docker", "exec", "nac_ldap",
        "ldapsearch", "-x",
        "-D", "cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn",
        "-w", "AdminPassword123!",
        "-b", "dc=attt,dc=ptit,dc=edu,dc=vn",
        "(objectClass=*)",
        "*", "userPassword"
    ]
    proc = run_cmd(cmd)
    raw_ldif = proc.stdout.decode('utf-8', errors='replace')

    # Làm sạch LDIF: bỏ các dòng comment metadata của ldapsearch để file gọn đẹp
    cleaned_lines = []
    in_entry = False
    for line in raw_ldif.splitlines():
        # Bỏ qua các dòng comment thông tin tìm kiếm
        if line.startswith("# search result") or line.startswith("# numResponses") or line.startswith("# numEntries"):
            continue
        if line.startswith("search: ") or line.startswith("result: "):
            continue
        cleaned_lines.append(line)

    clean_ldif = "\n".join(cleaned_lines).strip() + "\n"
    ldif_bytes = clean_ldif.encode('utf-8')

    os.makedirs(DATA_SYNC_DIR, exist_ok=True)
    with open(LDAP_DUMP_FILE, "wb") as f:
        f.write(ldif_bytes)

    # Đồng bộ cả vào ldap/init-ldap.ldif để clone mới hoặc rebuild container dùng ngay
    with open(INIT_LDAP_FILE, "wb") as f:
        f.write(ldif_bytes)

    # Đếm số lượng entry
    entry_count = clean_ldif.count("\ndn: ") + (1 if clean_ldif.startswith("dn: ") else 0)
    log(f"Đã lưu OpenLDAP snapshot ({entry_count} đối tượng/tài khoản) vào {os.path.relpath(LDAP_DUMP_FILE)}", "SUCCESS")
    log(f"Đã cập nhật đồng bộ file khởi tạo {os.path.relpath(INIT_LDAP_FILE)}", "SUCCESS")

def import_mariadb():
    """Nạp snapshot MariaDB vào container đang chạy"""
    if not os.path.exists(MARIADB_DUMP_FILE):
        log(f"Không tìm thấy file snapshot MariaDB tại {MARIADB_DUMP_FILE}", "ERROR")
        return False

    log("Đang khôi phục dữ liệu MariaDB từ snapshot...")
    with open(MARIADB_DUMP_FILE, "rb") as f:
        sql_content = f.read()

    cmd = ["docker", "exec", "-i", "nac_mariadb", "mariadb", "-u", "root", "-pRootPassword123!"]
    run_cmd(cmd, input_data=sql_content)

    # Xác thực số lượng bảng đã khôi phục
    verify_cmd = ["docker", "exec", "nac_mariadb", "mariadb", "-u", "root", "-pRootPassword123!", "-e", "USE radius; SELECT count(*) FROM information_schema.tables WHERE table_schema='radius';"]
    proc = run_cmd(verify_cmd)
    output = proc.stdout.decode('utf-8').strip()
    table_count = output.splitlines()[-1] if output else "N/A"
    log(f"Đã khôi phục thành công MariaDB ({table_count} bảng dữ liệu)", "SUCCESS")
    return True

def import_ldap():
    """Nạp snapshot OpenLDAP vào container đang chạy"""
    target_file = LDAP_DUMP_FILE if os.path.exists(LDAP_DUMP_FILE) else INIT_LDAP_FILE
    if not os.path.exists(target_file):
        log(f"Không tìm thấy file snapshot OpenLDAP tại {target_file}", "ERROR")
        return False

    log("Đang khôi phục dữ liệu OpenLDAP từ snapshot...")

    # Copy LDIF vào container
    run_cmd(["docker", "cp", target_file, "nac_ldap:/tmp/restore.ldif"])

    # Xóa sạch các cây thư mục con cũ để tránh xung đột 'Already exists'
    del_cmd = [
        "docker", "exec", "nac_ldap",
        "ldapdelete", "-x",
        "-D", "cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn",
        "-w", "AdminPassword123!",
        "-r",
        "ou=users,dc=attt,dc=ptit,dc=edu,dc=vn",
        "ou=groups,dc=attt,dc=ptit,dc=edu,dc=vn",
        "ou=services,dc=attt,dc=ptit,dc=edu,dc=vn",
        "ou=policies,dc=attt,dc=ptit,dc=edu,dc=vn"
    ]
    # Lệnh delete có thể trả về lỗi 32 (No such object) nếu cây con chưa có, ta cho phép bỏ qua
    run_cmd(del_cmd, check=False)

    # Nạp toàn bộ dữ liệu mới từ file LDIF
    add_cmd = [
        "docker", "exec", "nac_ldap",
        "ldapadd", "-x", "-c",
        "-D", "cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn",
        "-w", "AdminPassword123!",
        "-f", "/tmp/restore.ldif"
    ]
    run_cmd(add_cmd, check=False)

    # Dọn dẹp file tạm trong container
    run_cmd(["docker", "exec", "nac_ldap", "rm", "-f", "/tmp/restore.ldif"], check=False)

    # Xác thực số tài khoản người dùng
    check_cmd = [
        "docker", "exec", "nac_ldap",
        "ldapsearch", "-x",
        "-b", "ou=users,dc=attt,dc=ptit,dc=edu,dc=vn",
        "(objectClass=inetOrgPerson)", "uid"
    ]
    proc = run_cmd(check_cmd, check=False)
    user_count = proc.stdout.decode('utf-8').count("uid: ")
    log(f"Đã khôi phục thành công OpenLDAP ({user_count} tài khoản người dùng)", "SUCCESS")
    return True

def do_export():
    """Hành động Export"""
    print("\n" + "=" * 65)
    print(" BẮT ĐẦU XUẤT SNAPSHOT DATABASE ĐỂ ĐỒNG BỘ LÊN GIT")
    print("=" * 65)
    ensure_containers_up()
    export_mariadb()
    export_ldap()

    # Tự động stage vào Git nếu có repo Git
    if os.path.exists(os.path.join(PROJECT_ROOT, ".git")):
        try:
            run_cmd(["git", "add", "data_sync/", "ldap/init-ldap.ldif"])
            log("Đã tự động thêm các file snapshot vào Git Staging (git add)", "SUCCESS")
        except Exception:
            pass

    print("=" * 65)
    log("HOÀN TẤT XUẤT DỮ LIỆU!", "SUCCESS")
    print("Bây giờ bạn có thể an tâm commit và đẩy lên Git:")
    print("  git commit -m 'Cap nhat du lieu database moi nhat'")
    print("  git push")
    print("=" * 65 + "\n")

def do_import():
    """Hành động Import"""
    print("\n" + "=" * 65)
    print(" BẮT ĐẦU ĐỒNG BỘ DỮ LIỆU TỪ GIT VÀO CONTAINER HỆ THỐNG")
    print("=" * 65)
    ensure_containers_up()
    m_ok = import_mariadb()
    l_ok = import_ldap()

    print("=" * 65)
    if m_ok and l_ok:
        log("TOÀN BỘ CƠ SỞ DỮ LIỆU ĐÃ ĐỒNG BỘ 100% THÀNH CÔNG!", "SUCCESS")
        print("Hệ thống trên máy này đã có đầy đủ tài khoản, mật khẩu, và cấu hình mới nhất.")
    else:
        log("Đồng bộ hoàn tất với một số cảnh báo. Vui lòng kiểm tra log ở trên.", "WARN")
    print("=" * 65 + "\n")

def do_status():
    """Xem trạng thái đồng bộ"""
    print("\n" + "=" * 65)
    print(" TRẠNG THÁI CÁC DỊCH VỤ VÀ SNAPSHOT DỮ LIỆU")
    print("=" * 65)
    containers = ["nac_mariadb", "nac_ldap", "nac_radius", "nac_dashboard"]
    for c in containers:
        status = "ĐANG CHẠY [ONLINE]" if check_container_running(c) else "ĐÃ DỪNG [OFFLINE]"
        print(f"  - {c.ljust(16)}: {status}")

    print("\nFile snapshot trong data_sync/:")
    for fpath in [MARIADB_DUMP_FILE, LDAP_DUMP_FILE, INIT_LDAP_FILE]:
        if os.path.exists(fpath):
            mtime = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(os.path.getmtime(fpath)))
            size_kb = os.path.getsize(fpath) / 1024
            print(f"  - {os.path.relpath(fpath).ljust(30)}: {size_kb:.1f} KB (Cập nhật lúc: {mtime})")
        else:
            print(f"  - {os.path.relpath(fpath).ljust(30)}: CHƯA TỒN TẠI (Hãy chạy export)")
    print("=" * 65 + "\n")

def do_install_hooks():
    """Cài đặt Git Hooks để tự động export khi commit và tự động import khi pull"""
    git_dir = os.path.join(PROJECT_ROOT, ".git")
    if not os.path.exists(git_dir):
        log("Không tìm thấy thư mục .git trong dự án này!", "ERROR")
        return

    hooks_dir = os.path.join(git_dir, "hooks")
    os.makedirs(hooks_dir, exist_ok=True)

    # 1. Pre-commit hook (tự động export trước khi commit)
    pre_commit_path = os.path.join(hooks_dir, "pre-commit")
    pre_commit_script = """#!/bin/sh
# Tự động xuất dữ liệu database trước khi commit
echo "[Git Hook] Dang tu dong xuat database snapshot truoc khi commit..."
python sync_data.py export
git add data_sync/ ldap/init-ldap.ldif
"""
    with open(pre_commit_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(pre_commit_script)

    # 2. Post-merge hook (tự động import sau khi git pull / git merge)
    post_merge_path = os.path.join(hooks_dir, "post-merge")
    post_merge_script = """#!/bin/sh
# Tự động nạp dữ liệu database sau khi git pull
echo "[Git Hook] Phat hien cap nhat tu Git! Dang tu dong dong bo database..."
python sync_data.py import
"""
    with open(post_merge_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(post_merge_script)

    log("Đã cài đặt Git Hook 'pre-commit' (Tự động export khi bạn gõ git commit)", "SUCCESS")
    log("Đã cài đặt Git Hook 'post-merge' (Tự động import khi bạn gõ git pull)", "SUCCESS")
    log("Từ bây giờ việc đồng bộ database diễn ra hoàn toàn tự động!", "SUCCESS")

def main():
    if len(sys.argv) < 2:
        print("""
Sử dụng:
  python sync_data.py export        : Xuất database MariaDB & LDAP thành snapshot để push Git
  python sync_data.py import        : Nạp dữ liệu snapshot từ Git vào các container của máy này
  python sync_data.py status        : Xem trạng thái các container và file snapshot
  python sync_data.py install-hooks : Cài đặt Git Hooks để tự động đồng bộ khi commit và pull
""")
        return

    cmd = sys.argv[1].lower().strip()
    if cmd == "export":
        do_export()
    elif cmd == "import":
        do_import()
    elif cmd == "status":
        do_status()
    elif cmd == "install-hooks":
        do_install_hooks()
    else:
        log(f"Lệnh không hợp lệ: '{cmd}'. Dùng export, import, status, hoặc install-hooks.", "ERROR")

if __name__ == "__main__":
    main()
