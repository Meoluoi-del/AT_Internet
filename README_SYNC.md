# HƯỚNG DẪN ĐỒNG BỘ CƠ SỞ DỮ LIỆU QUA GIT (DATABASE SYNC GUIDE)

Dự án này sử dụng 2 hệ quản trị dữ liệu:
1. **MariaDB (`nac_mariadb`):** Lưu trữ chính sách mạng Dynamic VLAN, log kiểm toán (audit logs), thông tin xác thực 2 lớp (MFA/TOTP), các phiên đăng nhập SSO và trạng thái khóa brute-force.
2. **OpenLDAP (`nac_ldap`):** Thư mục danh tính người dùng (Sinh viên, Giảng viên, Quản trị viên, Nhóm quyền).

Để các thành viên trong nhóm luôn có dữ liệu giống nhau khi làm việc trên các máy tính khác nhau, hệ thống đã trang bị bộ công cụ **Git Database Sync Pipeline**.

---

## CÁCH SỬ DỤNG NHANH (1-CLICK)

### 1. KHI BẠN LÀM XONG VÀ MUỐN ĐẨY LÊN GIT (MÁY CỦA BẠN):
Mỗi khi bạn thêm tài khoản mới, đổi mật khẩu hoặc thay đổi dữ liệu:
- **Cách 1 (Chuột):** Nhấp đúp vào file `export_data.bat`.
- **Cách 2 (Terminal):** Chạy lệnh:
  ```bash
  python sync_data.py export
  ```
- Sau đó commit và đẩy lên Git như bình thường:
  ```bash
  git commit -m "Cap nhat du lieu he thong"
  git push
  ```

---

### 2. KHI BẠN BÈ / MÁY KHÁC KÉO CODE VỀ (MÁY ĐỒNG ĐỘI):
Sau khi bạn bè chạy `git pull`:
- **Cách 1 (Chuột):** Nhấp đúp vào file `import_data.bat`.
- **Cách 2 (Terminal):** Chạy lệnh:
  ```bash
  python sync_data.py import
  ```
*Hệ thống sẽ tự động nạp toàn bộ tài khoản và bảng dữ liệu mới nhất vào Docker chỉ trong 5 giây!*

---

## ĐỒNG BỘ HOÀN TOÀN TỰ ĐỘNG (GIT HOOKS)
Nếu bạn không muốn phải nhớ chạy lệnh thủ công, hãy kích hoạt Git Hooks:
```bash
python sync_data.py install-hooks
```
Sau khi cài đặt:
- Mỗi khi bạn gõ `git commit`, hệ thống sẽ **tự động export** dữ liệu mới nhất vào commit.
- Mỗi khi bạn của bạn gõ `git pull`, hệ thống sẽ **tự động import** dữ liệu vào Docker.

---

## CÁC LỆNH TIỆN ÍCH KHÁC
```bash
# Kiểm tra trạng thái container và thời gian cập nhật dữ liệu
python sync_data.py status
```
