# TÀI LIỆU THIẾT KẾ BƯỚC 4: SƠ ĐỒ KIẾN TRÚC HỆ THỐNG & SƠ ĐỒ LUỒNG XÁC THỰC (SEQUENCE DIAGRAM)

> **Dự án**: Quản lý truy cập mạng và xác thực trung tâm (NAC & Centralized Authentication)  
> **Môn học**: An toàn mạng - PTITHCM  
> **Phiên bản**: 1.0 (Ngày 1 - Bước 4)  

---

## I. TỔNG QUAN KIẾN TRÚC TOÀN HỆ THỐNG (SYSTEM ARCHITECTURE)

Hệ thống được thiết kế theo mô hình vi dịch vụ container hóa (Containerized Microservices), vận hành độc lập nhưng liên kết chặt chẽ qua một mạng logic nội bộ bảo mật (`nac-net`).

### 1. Sơ đồ khối các thành phần trong hệ thống

```text
+-----------------------------------------------------------------------------------------+
|                                    HẠ TẦNG DOCKER (nac-net)                              |
|                                                                                         |
|  +-----------------------+                         +----------------------------------+ |
|  |     CLIENT / TEST     |                         |         FLASK DASHBOARD          | |
|  |  (radtest / eapol)    |                         |  - Giao diện quản trị Admin      | |
|  |  - Giả lập End-user   |                         |  - Auditor tra cứu log           | |
|  |  - Giả lập Attacker   |                         |  - Module Active Defense         | |
|  +-----------+-----------+                         +----------------+-----------------+ |
|              | (UDP: 1812/1813)                                     |                   |
|              v                                                      |                   |
|  +-----------+-----------+        LDAP Bind / Search                v                   |
|  |      FREERADIUS       |----------------------------->+-----------+-----------+       |
|  |  (Authentication &    |   (Port 389 - StartTLS)      |     OPENLDAP SERVER       |       |
|  |   Dynamic NAC Engine) |<-----------------------------|  - Users (admin, gv, sv)  |       |
|  +-----------+-----------+        User info & Groups    |  - Groups (quarantine,..) |       |
|              |                                          +-----------------------+--+       |
|              | SQL Query (Policies / radgroupreply)                             ^           |
|              | SQL Accounting (radpostauth / radacct)                           |           |
|              v                                                      Sync Groups |           |
|  +-----------+-----------+                                          & Users     |           |
|  |    MARIADB / MYSQL    |<-----------------------------------------------------+           |
|  |  - policy_matrix      |                 Cập nhật VLAN & Đọc Log                          |
|  |  - radgroupreply      |                                                                  |
|  |  - radpostauth        |                                                                  |
|  |  - audit_logs         |                                                                  |
|  +-----------------------+                                                                  |
+-----------------------------------------------------------------------------------------+
```

### 2. Bảng phân định vai trò và cổng giao tiếp dịch vụ

| Dịch vụ Container | Tên Container | Cổng nội bộ / Public | Giao thức | Chức năng chi tiết |
| :--- | :--- | :--- | :---: | :--- |
| **OpenLDAP** | `nac_ldap` | `389:389` | LDAP / StartTLS | Thư mục danh tính tập trung (Single Source of Truth), quản lý DN người dùng và nhóm. |
| **FreeRADIUS** | `nac_radius` | `1812:1812/udp`<br>`1813:1813/udp` | RADIUS (RFC 2865 / RFC 2866) | Tiếp nhận yêu cầu truy cập mạng, xác thực credentials qua LDAP, truy vấn VLAN từ SQL và đóng gói Access-Accept / Reject. |
| **Database** | `nac_mariadb` | `3306:3306` | MySQL Wire | Lưu trữ bảng chính sách `policy_matrix`, các thuộc tính RADIUS `radgroupreply`, nhật ký xác thực `radpostauth` và nhật ký quản trị `audit_logs`. |
| **Web Dashboard** | `nac_dashboard`| `5000:5000` | HTTP / HTTPS | Giao diện điều khiển trung tâm: quản trị tài khoản LDAP, chỉnh sửa ma trận VLAN, giám sát phiên, và chạy ngầm worker phát hiện brute-force. |
| **Client Test** | `nac_client` | *Internal* | UDP / CLI | Chứa bộ công cụ `radtest`, `eapol_test` và test script để kiểm thử các kịch bản mạng tự động. |

---

## II. SƠ ĐỒ LUỒNG TUẦN TỰ (SEQUENCE DIAGRAMS)

### 1. Luồng Xác thực thành công & Cấp Dynamic VLAN (US01 & US02)
Áp dụng khi người dùng hợp lệ (ví dụ: `sv_an`) gửi yêu cầu kết nối mạng.

```text
[Người dùng / Client]   [FreeRADIUS Server]    [OpenLDAP Directory]     [MariaDB Database]
         |                       |                       |                       |
         | 1. Access-Request     |                       |                       |
         |    (uid, password)    |                       |                       |
         |---------------------->|                       |                       |
         |                       | 2. LDAP Search & Bind |                       |
         |                       |    (Check credential) |                       |
         |                       |---------------------->|                       |
         |                       | 3. Trả về kết quả:    |                       |
         |                       |    - Password OK      |                       |
         |                       |    - Group: sinhvien  |                       |
         |                       |<----------------------|                       |
         |                       |                                               |
         |                       | 4. SQL Query radgroupreply cho 'sinhvien'    |
         |                       |---------------------------------------------->|
         |                       | 5. Trả về thuộc tính:                         |
         |                       |    - Tunnel-Type = VLAN                       |
         |                       |    - Tunnel-Medium-Type = IEEE-802            |
         |                       |    - Tunnel-Private-Group-Id = "20"           |
         |                       |<----------------------------------------------|
         |                       |                                               |
         |                       | 6. Ghi log xác thực thành công vào radpostauth|
         |                       |---------------------------------------------->|
         | 7. Access-Accept      |                                               |
         |    (VLAN ID = 20)     |                                               |
         |<----------------------|                                               |
         |                       |                                               |
```

---

### 2. Luồng Xác thực thất bại (Sai mật khẩu hoặc tài khoản không tồn tại)
Áp dụng khi kẻ xấu dò mật khẩu hoặc nhập sai thông tin.

```text
[Người dùng / Client]   [FreeRADIUS Server]    [OpenLDAP Directory]     [MariaDB Database]
         |                       |                       |                       |
         | 1. Access-Request     |                       |                       |
         |    (uid, wrong_pass)  |                       |                       |
         |---------------------->|                       |                       |
         |                       | 2. LDAP Bind kiểm tra |                       |
         |                       |---------------------->|                       |
         |                       | 3. LDAP BIND_FAIL     |                       |
         |                       |<----------------------|                       |
         |                       |                                               |
         |                       | 4. Ghi log thất bại vào bảng radpostauth     |
         |                       |    (reply = 'Access-Reject', pass = '***')    |
         |                       |---------------------------------------------->|
         | 5. Access-Reject      |                                               |
         |<----------------------|                                               |
         |                       |                                               |
```

---

### 3. Luồng Phòng vệ chủ động: Tự động phát hiện Brute-force và Cô lập (US09)
Áp dụng khi một tài khoản nhập sai mật khẩu quá 5 lần trong 3 phút.

```text
[Attacker / Tool]     [FreeRADIUS]          [MariaDB]         [Active Defense Worker]     [OpenLDAP]
       |                    |                   |                        |                    |
       | 1. Gửi liên tiếp   |                   |                        |                    |
       |    5 lần sai pass  |                   |                        |                    |
       |------------------->|                   |                        |                    |
       |                    | 2. Ghi 5 bản ghi  |                        |                    |
       |                    |    Reject vào DB  |                        |                    |
       |                    |------------------>|                        |                    |
       |                    |                   |                        |                    |
       |                    |                   | 3. Quét kiểm tra định kỳ                    |
       |                    |                   |    (COUNT Reject >= 5 trong 3 phút)         |
       |                    |                   |<-----------------------|                    |
       |                    |                   | 4. Báo động: sv_test   |                    |
       |                    |                   |----------------------->|                    |
       |                    |                   |                        |                    |
       |                    |                   |                        | 5. Cập nhật nhóm:  |
       |                    |                   |                        |    Chuyển sv_test  |
       |                    |                   |                        |    sang quarantine |
       |                    |                   |                        |------------------->|
       |                    |                   |                        |                    |
       |                    |                   | 6. Ghi Audit Log       |                    |
       |                    |                   |    & Bắn cảnh báo web  |                    |
       |                    |                   |<-----------------------|                    |
       |                    |                   |                        |                    |
       | (Sau đó: Attacker  |                   |                        |                    |
       |  nhập ĐÚNG pass)   |                   |                        |                    |
       | 7. Access-Request  |                   |                        |                    |
       |    (pass ĐÚNG)     |                   |                        |                    |
       |------------------->|                   |                        |                    |
       |                    | 8. Hỏi LDAP       |                        |                    |
       |                    |---------------------------------------------------------------->|
       |                    | 9. Pass ĐÚNG, nhưng Group = 'quarantine'                        |
       |                    |<----------------------------------------------------------------|
       |                    | 10. Truy vấn SQL cho nhóm 'quarantine'                          |
       |                    |------------------>|                                             |
       |                    | 11. Trả về VLAN 99|                                             |
       |                    |<------------------|                                             |
       | 12. Access-Accept  |                   |                        |                    |
       |     VLAN ID = 99   |                   |                        |                    |
       |     (Bị cô lập!)   |                   |                        |                    |
       |<-------------------|                   |                        |                    |
```

---

### 4. Luồng Quản trị viên thay đổi chính sách VLAN trên Dashboard (US05)

```text
[Admin Dashboard]                [Flask Backend]             [MariaDB Database]       [FreeRADIUS]
       |                                |                            |                      |
       | 1. Sửa chính sách:             |                            |                      |
       |    sinhvien: VLAN 20 -> 25     |                            |                      |
       |------------------------------->|                            |                      |
       |                                | 2. Cập nhật bảng           |                      |
       |                                |    policy_matrix           |                      |
       |                                |    (vlan_id = 25)          |                      |
       |                                |--------------------------->|                      |
       |                                | 3. Cập nhật bảng           |                      |
       |                                |    radgroupreply           |                      |
       |                                |    (value = '25')          |                      |
       |                                |--------------------------->|                      |
       |                                | 4. Ghi bảng audit_logs     |                      |
       |                                |--------------------------->|                      |
       | 5. Phản hồi thành công (200 OK)|                            |                      |
       |<-------------------------------|                            |                      |
       |                                |                            |                      |
       |                                |                            | 6. Lần xác thực tới  |
       |                                |                            |    FreeRADIUS đọc SQL|
       |                                |                            |    nhận ngay VLAN 25!|
       |                                |                            |<---------------------|
```

---

## III. NGUYÊN TẮC AN TOÀN TRONG GIAO TIẾP NỘI BỘ (DEFENSE IN DEPTH)

1. **Phân vùng mạng container (Network Isolation)**: Toàn bộ các cổng kết nối dữ liệu cơ sở dữ liệu (3306), LDAP nội bộ (389) chỉ mở trong mạng Docker bridge `nac-net`. Chỉ có cổng Web Dashboard (5000) và cổng RADIUS (1812, 1813) được ánh xạ ra ngoài máy chủ để phục vụ người dùng và thiết bị mạng.
2. **Không phân quyền trực tiếp (Decoupled Authentication)**: Người dùng mạng không bao giờ được cấp kết nối trực tiếp đến LDAP hay cơ sở dữ liệu; toàn bộ yêu cầu bắt buộc phải ủy quyền qua máy chủ FreeRADIUS.
3. **Chống chối bỏ (Non-repudiation)**: Bất kỳ thay đổi cấu hình hay thao tác xác thực nào đều sinh ra bản ghi nhật ký vĩnh viễn (Audit Log / Authentication Log) có dấu thời gian (Timestamp) chính xác đến microsecond.
