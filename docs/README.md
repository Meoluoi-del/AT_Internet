# HỆ THỐNG QUẢN LÝ TRUY CẬP MẠNG VÀ XÁC THỰC TRUNG TÂM (CENTRALIZED NAC & AAA)

> **Môn học**: An toàn mạng - Học viện Công nghệ Bưu chính Viễn thông (PTITHCM)  
> **Kiến trúc**: Microservices Docker (OpenLDAP + FreeRADIUS + MariaDB + Flask Dashboard)  
> **Tiêu chuẩn**: RFC 2865, RFC 2866, RFC 2868, RFC 3580 (Dynamic 802.1Q VLAN Assignment)  

---

## 📌 I. GIỚI THIỆU TỔNG QUAN

Dự án hiện thực hóa giải pháp **Kiểm soát truy cập mạng (Network Access Control - NAC)** và **Xác thực tập trung theo mô hình AAA** nhằm giải quyết triệt để rủi ro an toàn thông tin khi quản trị tài khoản phân tán trên các thiết bị mạng:

1. **Authentication (Xác thực tập trung)**: Đưa toàn bộ danh tính người dùng và mật khẩu băm `{SSHA}` về thư mục duy nhất **OpenLDAP** (*Single Source of Truth*).
2. **Authorization (Cấp quyền động theo vai trò)**: Máy chủ **FreeRADIUS** tự động cấp phát phân đoạn mạng logic (**Dynamic VLAN Assignment**) dựa trên nhóm LDAP:
   - Nhóm `quantri` $\to$ **VLAN 10** (Quản trị mạng nội bộ)
   - Nhóm `giangvien` $\to$ **VLAN 30** (Cán bộ giảng viên, LMS, máy chủ điểm)
   - Nhóm `sinhvien` $\to$ **VLAN 20** (Sinh viên học tập, Internet thông thường)
   - Nhóm `quarantine` $\to$ **VLAN 99** (Phân đoạn cách ly đối tượng vi phạm hoặc nghi ngờ)
3. **Accounting (Ghi nhận & Kiểm toán)**: Lưu trữ toàn bộ nhật ký phiên kết nối mạng (`radacct`) và nhật ký xác thực (`radpostauth`) vào cơ sở dữ liệu **MariaDB**.
4. **Active Defense (Phòng vệ chủ động)**: Tự động phát hiện tấn công dò mật khẩu (Brute-force: quá 5 lần sai trong 3 phút) $\to$ Tự động chuyển tài khoản sang nhóm `quarantine` (VLAN 99) và bắn cảnh báo lên Dashboard.
5. **Web Dashboard Quản trị**: Giao diện trực quan phân quyền chặt chẽ giữa **Admin** (toàn quyền) và **Auditor** (chỉ đọc).

---

## 📂 II. CẤU TRÚC THƯ MỤC DỰ ÁN

```text
D:\AT_Internet\
├── docker-compose.yml              # Khởi động toàn bộ 4 container dịch vụ bằng 1 lệnh
├── .env                            # Biến môi trường cấu hình mật khẩu và cổng dịch vụ
├── .env.example                    # File mẫu biến môi trường
├── README.md                       # Hướng dẫn chi tiết chạy và kiểm thử hệ thống
│
├── docs\                           # TÀI LIỆU HỌC THUẬT VÀ THIẾT KẾ (.md & .docx)
│   ├── day1_scope_and_user_stories.md / .docx
│   ├── day1_ldap_dit_design.md / .docx
│   ├── day1_policy_matrix_design.md / .docx
│   ├── day1_architecture_and_sequence_diagram.md / .docx
│   ├── bao_cao_do_an_an_toan_mang.md / .docx   # BÁO CÁO TOÀN DIỆN 6 CHƯƠNG
│   └── slide_thuyet_trinh.md / .docx           # ĐỀ CƯƠNG SLIDE THUYẾT TRÌNH BẢO VỆ
│
├── ldap\                           # THƯ MỤC DANH TÍNH TẬP TRUNG
│   └── init-ldap.ldif              # Dữ liệu khởi tạo: OUs, Groups, Users, SSHA Hashes
│
├── sql\                            # CƠ SỞ DỮ LIỆU CHÍNH SÁCH & LOG
│   └── init-policy.sql             # Khởi tạo bảng chính sách, radgroupreply, audit_logs
│
├── radius\                         # MÁY CHỦ AAA & DYNAMIC NAC (FREERADIUS)
│   ├── Dockerfile                  # Build image FreeRADIUS nạp module LDAP và MySQL
│   ├── clients.conf                # Khai báo Client / NAS cho phép và Shared Secret
│   ├── mods-available\
│   │   ├── ldap                    # Cấu hình kết nối OpenLDAP port 389
│   │   └── sql                     # Cấu hình kết nối MariaDB port 3306
│   └── sites-available\
│       └── default                 # Cấu hình logic cấp Dynamic VLAN qua Unlang
│
├── dashboard\                      # GIAO DIỆN QUẢN TRỊ TRUNG TÂM (FLASK APP)
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app.py                      # Backend API, phân quyền Admin / Auditor
│   ├── config.py
│   ├── models.py                   # Tương tác MariaDB (policy_matrix, logs)
│   ├── ldap_client.py              # Tương tác OpenLDAP (CRUD User, Hash SSHA)
│   ├── detector.py                 # Worker ngầm phát hiện Brute-force & Auto-Quarantine
│   └── templates\                  # Giao diện Web hiện đại (Tailwind CSS)
│       ├── base.html, login.html, index.html, users.html,
│       ├── policies.html, logs.html, sessions.html, audit.html
│
└── tests\                          # BỘ KỊCH BẢN KIỂM THỬ TỰ ĐỘNG
    ├── radius_client.py            # Thư viện thuần Python giả lập RADIUS Client (RFC 2865)
    ├── simulate_auth.py            # Kiểm thử xác thực từng user và kiểm tra VLAN
    ├── simulate_bruteforce.py      # Giả lập tấn công Brute-force & kiểm tra cô lập
    └── verify_all.py               # Kiểm thử chất lượng toàn diện (End-to-End)
```

---

## 🔑 III. DANH SÁCH TÀI KHOẢN HỆ THỐNG CÓ SẴN

### 1. Tài khoản đăng nhập Web Dashboard (http://localhost:5000)
| Username | Mật khẩu | Quyền hạn (Role) | Chức năng |
| :--- | :--- | :---: | :--- |
| **`admin`** | `AdminPassword123!` | **Admin** (Toàn quyền) | Thêm/xóa user LDAP, sửa VLAN, mở khóa tài khoản bị cách ly. |
| **`auditor`** | `AuditorPass123!` | **Auditor** (Chỉ đọc) | Xem nhật ký xác thực, phiên mạng, audit logs. Mọi nút sửa/xóa bị ẩn và chặn API. |

### 2. Tài khoản người dùng mạng trên OpenLDAP
| Username (`uid`) | Mật khẩu mặc định | Nhóm LDAP | VLAN cấp phát | Mục đích kiểm thử |
| :--- | :--- | :--- | :---: | :--- |
| `admin01` | `P@ssword123!` | `quantri` | **VLAN 10** | Quản trị mạng nội bộ, timeout 2h |
| `gv_nguyen` | `P@ssword123!` | `giangvien` | **VLAN 30** | Giảng viên, LMS, máy chủ điểm, timeout 8h |
| `sv_an` | `P@ssword123!` | `sinhvien` | **VLAN 20** | Sinh viên học tập thông thường, timeout 4h |
| `sv_binh` | `P@ssword123!` | `sinhvien` | **VLAN 20** | Sinh viên học tập thông thường |
| `sv_test` | `P@ssword123!` | `sinhvien` $\to$ `quarantine` | **VLAN 20 $\to$ 99** | Tài khoản dùng để giả lập tấn công Brute-force |

---

## 🚀 IV. HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG

### Bước 1: Khởi động toàn bộ cụm dịch vụ Docker
Mở PowerShell hoặc Command Prompt tại thư mục dự án (`D:\AT_Internet`) và chạy:

```powershell
docker-compose up -d --build
```

Lệnh này sẽ tự động:
1. Khởi động OpenLDAP (`nac_ldap`) và tự động nạp cấu trúc DIT, người dùng mẫu từ `ldap/init-ldap.ldif`.
2. Khởi động MariaDB (`nac_mariadb`) và tự động nạp bảng chính sách, thuộc tính VLAN từ `sql/init-policy.sql`.
3. Biên dịch và chạy FreeRADIUS (`nac_radius`) nạp module LDAP và MySQL.
4. Biên dịch và chạy Flask Dashboard (`nac_dashboard`) cùng tiến trình ngầm Active Defense Detector.

### Bước 2: Kiểm tra trạng thái hoạt động các container
```powershell
docker-compose ps
```
Cả 4 container (`nac_ldap`, `nac_mariadb`, `nac_radius`, `nac_dashboard`) đều hiển thị trạng thái `Up`.

---

## 🧪 V. HƯỚNG DẪN CHẠY CÁC KỊCH BẢN KIỂM THỬ (TEST SCENARIOS)

Nhóm nghiên cứu đã xây dựng sẵn bộ công cụ kiểm thử tự động bằng Python trong thư mục `tests/`:

### Kịch bản 1: Kiểm thử toàn diện hệ thống (End-to-End Verification)
Kiểm tra kết nối mạng của 4 cổng dịch vụ và kiểm thử xác thực cả 3 vai trò (Sinh viên, Giảng viên, Quản trị, Mật khẩu sai):
```powershell
python tests\verify_all.py
```
**Kết quả kỳ vọng**:
- `sv_an` nhận `Access-Accept` kèm **VLAN 20**.
- `gv_nguyen` nhận `Access-Accept` kèm **VLAN 30**.
- `admin01` nhận `Access-Accept` kèm **VLAN 10**.
- Mật khẩu sai nhận `Access-Reject`.

### Kịch bản 2: Kiểm thử xác thực người dùng tùy ý
```powershell
# Cú pháp: python tests\simulate_auth.py <username> <password>
python tests\simulate_auth.py sv_an P@ssword123!
```

### Kịch bản 3: Giả lập tấn công Brute-force và Phòng vệ chủ động (Active Defense)
```powershell
python tests\simulate_bruteforce.py sv_test
```
**Chuỗi hành động diễn ra tự động**:
1. Script gửi 6 lần mật khẩu sai liên tiếp vào máy chủ FreeRADIUS $\to$ Trả về `Access-Reject`.
2. Tiến trình Active Defense Detector ngầm phát hiện tài khoản `sv_test` bị đoán sai $\ge 5$ lần trong 3 phút.
3. Hệ thống tự động chuyển `sv_test` sang nhóm `quarantine` trên OpenLDAP.
4. Khi script thử lại với **MẬT KHẨU ĐÚNG (`P@ssword123!`)** $\to$ FreeRADIUS xác thực mật khẩu thành công nhưng ép nhận **VLAN 99 (Cách ly)**!
5. Mở Dashboard thấy xuất hiện dải banner đỏ cảnh báo vi phạm an toàn thông tin!

### Kịch bản 4: Kiểm thử thay đổi chính sách VLAN động không cần restart
1. Đăng nhập Web Dashboard tại `http://localhost:5000` bằng tài khoản `admin`.
2. Vào mục **Chính sách VLAN** $\to$ Chọn nhóm `sinhvien` $\to$ Đổi từ VLAN 20 sang **VLAN 25** $\to$ Bấm Lưu.
3. Chạy lại kiểm thử xác thực:
   ```powershell
   python tests\simulate_auth.py sv_an P@ssword123!
   ```
4. Gói tin `Access-Accept` lập tức trả về **VLAN 25** mà không cần khởi động lại FreeRADIUS!

---

## 🌐 VI. TRUY CẬP VÀ SỬ DỤNG GIAO DIỆN WEB DASHBOARD

Mở trình duyệt web và truy cập:
👉 **URL**: [http://localhost:5000](http://localhost:5000)

1. **Trang Đăng nhập**: Nhập `admin` / `AdminPassword123!` (Toàn quyền) hoặc `auditor` / `AuditorPass123!` (Chỉ xem).
2. **Trang Tổng quan (Overview)**: Xem biểu đồ tổng số tài khoản LDAP, phân đoạn VLAN, số lần Reject trong ngày và cảnh báo cô lập.
3. **Trang Tài khoản LDAP**:
   - Danh sách người dùng hiển thị kèm huy hiệu phân màu theo VLAN.
   - Nút **Thêm Tài Khoản Mới**: Nhập thông tin, mật khẩu tự động băm `{SSHA}` và nạp vào LDAP.
   - Nút **Cách ly**: Đẩy người dùng vào VLAN 99 ngay lập tức.
   - Nút **Mở khóa**: Phục hồi tài khoản bị cách ly trở lại mạng học tập.
4. **Trang Chính sách VLAN**: Chỉnh sửa VLAN ID, thời lượng phiên `Session-Timeout`, `Idle-Timeout`.
5. **Trang Log Xác thực (RADIUS)**: Lọc và tra cứu toàn bộ lịch sử đăng nhập mạng theo thời gian thực.
6. **Trang Nhật ký Audit Admin**: Bảng chỉ cho phép ghi (Append-Only) lưu vết toàn bộ hành vi của quản trị viên để bảo đảm tính minh bạch và chống chối bỏ.

---

## 🛑 VII. DỪNG VÀ DỌN DẸP MÔI TRƯỜNG

Khi hoàn thành buổi báo cáo hoặc kiểm thử:
```powershell
# Dừng các container
docker-compose stop

# Dừng và xóa toàn bộ container
docker-compose down
```
