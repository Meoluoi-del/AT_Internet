# TÀI LIỆU THIẾT KẾ BƯỚC 3: MA TRẬN CHÍNH SÁCH PHÂN QUYỀN MẠNG (POLICY MATRIX)

> **Dự án**: Quản lý truy cập mạng và xác thực trung tâm (NAC & Centralized Authentication)  
> **Môn học**: An toàn mạng - PTITHCM  
> **Phiên bản**: 1.0 (Ngày 1 - Bước 3)  

---

## I. CƠ SỞ KHOA HỌC VÀ LÝ THUYẾT AN TOÀN THÔNG TIN

Trong kiến trúc AAA (Authentication - Authorization - Accounting), sau khi pha **Xác thực (Authentication)** hoàn tất để xác định "Người dùng là ai" từ OpenLDAP, hệ thống bước vào pha **Cấp quyền (Authorization)** để trả lời câu hỏi "Người dùng được phép truy cập vào vùng mạng nào và với những đặc quyền gì".

Bước 3 áp dụng trực tiếp các nguyên lý cốt lõi trong giáo trình An toàn mạng:

1. **Mô hình kiểm soát truy cập dựa trên vai trò (Role-Based Access Control - RBAC)**:
   - Quyền truy cập không gán trực tiếp cho từng cá nhân riêng lẻ mà gán thông qua **Vai trò/Nhóm (Role/Group)**.
   - Người dùng được ánh xạ vào các nhóm LDAP: `quantri`, `giangvien`, `sinhvien`, `quarantine`.
   - Chính sách mạng được gắn với Nhóm, cho phép tự động thừa kế quyền khi người dùng chuyển đổi vai trò.

2. **Nguyên tắc phân đoạn mạng (Network Segmentation & Least Privilege)**:
   - Phân chia một mạng vật lý duy nhất thành nhiều mạng con logic cô lập (VLAN) nhằm ngăn chặn việc lây nhiễm mã độc theo chiều ngang (*Lateral Movement*), nghe lén gói tin (*Sniffing/ARP Spoofing*), hoặc quét mạng trái phép.
   - Áp dụng nguyên tắc **Đặc quyền tối thiểu (Principle of Least Privilege)**: Sinh viên chỉ được truy cập tài nguyên học tập và Internet, không được phép chạm tới vùng máy chủ quản trị mạng hay hệ thống điểm của giảng viên.

3. **Mô hình phòng thủ 3D & Chủ động ứng phó sự cố (Active Defense)**:
   - *Phòng ngừa (Prevention)*: Ngăn cách triệt để các luồng dữ liệu nhạy cảm bằng phân đoạn VLAN.
   - *Phát hiện (Detection)*: Ghi nhận và theo dõi các hành vi bất thường, phát hiện vượt ngưỡng đăng nhập sai.
   - *Răn đe / Phản ứng (Deterrence & Response)*: Lập tức cô lập đối tượng vi phạm bằng cách đẩy vào phân đoạn mạng cách ly (`quarantine` - VLAN 99), biến nguy cơ mất an toàn thành sự cố được kiểm soát trong vùng sandbox.

---

## II. CHUẨN GIAO THỨC VÀ CÁC THUỘC TÍNH RADIUS CHO DYNAMIC VLAN

Để thực hiện gán VLAN động (*Dynamic VLAN Assignment - DVA*) mà không cần cấu hình cổng switch thủ công, FreeRADIUS sử dụng các cặp thuộc tính-giá trị (**AVP - Attribute-Value Pairs**) theo các chuẩn quốc tế:
- **RFC 2868**: *RADIUS Attributes for Tunnel Protocol Support* (Định nghĩa các thuộc tính thiết lập đường hầm mạng).
- **RFC 3580**: *IEEE 802.1X Remote Authentication Dial In User Service (RADIUS) Usage Guidelines* (Hướng dẫn sử dụng thuộc tính RADIUS trong kiểm soát truy cập cổng 802.1X).

Khi máy chủ FreeRADIUS quyết định cấp quyền cho người dùng, trong gói tin phản hồi **`Access-Accept`** bắt buộc phải chứa bộ 3 thuộc tính cốt lõi sau:

```text
Tunnel-Type = VLAN (Giá trị số: 13)
Tunnel-Medium-Type = IEEE-802 (Giá trị số: 6)
Tunnel-Private-Group-Id = "<VLAN_ID>" (Chuỗi chuỗi số đại diện cho VLAN thẻ 802.1Q)
```

### Các thuộc tính bổ sung gia cố an ninh (Security Hardening Attributes):
- **`Session-Timeout`**: Thời lượng tối đa (tính bằng giây) của một phiên kết nối trước khi thiết bị phải tái xác thực (*Re-authentication*). Điều này ngăn chặn kẻ xấu chiếm dụng phiên đăng nhập bỏ quên (*Session Hijacking*).
- **`Idle-Timeout`**: Thời gian chờ (tính bằng giây) tự động ngắt kết nối nếu thiết bị không phát sinh lưu lượng mạng.
- **`Termination-Action`**: Thiết lập giá trị `1` (*RADIUS-Request*) để khi hết `Session-Timeout`, thiết bị mạng chủ động gửi yêu cầu xác thực ngầm mà không gây ngắt quãng trải nghiệm của người dùng hợp lệ.

---

## III. MA TRẬN CHÍNH SÁCH PHÂN QUYỀN MẠNG (POLICY MATRIX)

Bảng ma trận quy định chi tiết mối quan hệ giữa Nhóm người dùng, Phân đoạn VLAN, Phạm vi mạng, Thời hạn phiên làm việc và Quyền truy cập:

| Nhóm LDAP (`Group`) | VLAN ID | Tên phân đoạn | Dải IP / CIDR giả định | Session Timeout | Idle Timeout | Phạm vi tài nguyên được truy cập |
| :--- | :---: | :--- | :--- | :---: | :---: | :--- |
| **`quantri`** | **10** | Management / Admin | `10.10.10.0/24` | 7.200s *(2h)* | 900s *(15m)* | **Toàn quyền (Full Access)**: Quản trị switch, máy chủ LDAP, RADIUS, DB, Web Dashboard, Internet. |
| **`giangvien`** | **30** | Faculty / Staff | `10.10.30.0/24` | 28.800s *(8h)* | 1.800s *(30m)* | **Nghiệp vụ đào tạo**: Máy chủ nhập điểm, cổng thông tin cán bộ, thư viện tài liệu, dịch vụ in ấn, Internet. Không chạm vào VLAN 10. |
| **`sinhvien`** | **20** | Student | `10.10.20.0/24` | 14.400s *(4h)* | 600s *(10m)* | **Học tập thông thường**: Cổng thông tin đào tạo (Portal sinh viên), Internet. Áp dụng Client Isolation (chống quét IP trong cùng VLAN). |
| **`quarantine`** | **99** | Quarantine / Isolated | `10.10.99.0/24` | 1.800s *(30m)* | 300s *(5m)* | **Vùng cách ly bảo vệ**: Chặn toàn bộ kết nối ra Internet và mạng nội bộ. Chỉ cho phép truy cập Web Portal cảnh báo đổi mật khẩu và liên hệ Admin. |
| *(Mặc định / Khác)* | *Reject* | Không xác định | *None* | *N/A* | *N/A* | **Từ chối truy cập (Access-Reject)**: Bất kỳ tài khoản nào không thuộc 4 nhóm trên sẽ bị từ chối kết nối ngay lập tức. |

---

## IV. QUY TẮC GIẢI QUYẾT XUNG ĐỘT QUYỀN (CONFLICT RESOLUTION RULES)

Trong thực tế vận hành mạng tổ chức, một tài khoản người dùng có thể vô tình hoặc cố ý được gán vào nhiều nhóm khác nhau trên LDAP (ví dụ: một cán bộ vừa thuộc nhóm `quantri` vừa thuộc `giangvien`, hoặc tài khoản bị tấn công vừa thuộc `sinhvien` vừa rơi vào `quarantine`). Để đảm bảo tính nhất quán và bảo mật tuyệt đối, hệ thống áp dụng các quy tắc sau:

### 1. Quy tắc Ưu tiên tuyệt đối của Cách ly (Quarantine Override Rule)
> **Nguyên tắc**: *An toàn là trên hết (Safety First).*
- Nếu người dùng thuộc nhóm `quarantine`, **mọi quyền hạn khác ngay lập tức bị vô hiệu hóa**.
- Hệ thống sẽ ép buộc trả về **VLAN 99** bất kể người dùng có đồng thời là thành viên của `quantri`, `giangvien` hay `sinhvien`.

### 2. Thứ tự ưu tiên phân quyền (Priority Hierarchy)
Khi một người dùng thuộc nhiều nhóm thông thường (không bị quarantine), hệ thống phân xử theo độ ưu tiên từ cao xuống thấp:

$$\text{Quarantine (VLAN 99)} \gg \text{Quản trị (VLAN 10)} > \text{Giảng viên (VLAN 30)} > \text{Sinh viên (VLAN 20)}$$

| Thứ tự ưu tiên | Nhóm | VLAN ID | Trọng số ưu tiên (Priority) |
| :---: | :--- | :---: | :---: |
| **1 (Cao nhất - Override)** | `quarantine` | 99 | 1000 |
| **2** | `quantri` | 10 | 100 |
| **3** | `giangvien` | 30 | 50 |
| **4 (Thấp nhất)** | `sinhvien` | 20 | 10 |

---

## V. THIẾT KẾ CƠ SỞ DỮ LIỆU CHÍNH SÁCH ĐỘNG (DATABASE SCHEMA)

Để đáp ứng **User Story US05** (*"Admin có thể chỉnh sửa bảng chính sách Nhóm $\to$ VLAN trên giao diện Web Dashboard, và thay đổi có hiệu lực ngay ở lần xác thực kế tiếp mà không cần khởi động lại FreeRADIUS"*), chính sách được lưu trữ tập trung trong Cơ sở dữ liệu SQL (MySQL/PostgreSQL) với 2 bảng:

### 1. Bảng `policy_matrix` (Dành riêng cho Web Dashboard quản trị)
Bảng này phản ánh chính xác các thông tin nghiệp vụ mà Quản trị viên nhìn thấy và tùy biến trên màn hình Dashboard:
- `id` (INT, Primary Key, Auto Increment)
- `group_name` (VARCHAR(64), Unique): Tên nhóm tương ứng trên LDAP (`quantri`, `giangvien`, `sinhvien`, `quarantine`).
- `vlan_id` (INT): Mã phân đoạn mạng VLAN gán cho nhóm.
- `vlan_name` (VARCHAR(64)): Tên định danh của mạng VLAN.
- `subnet_cidr` (VARCHAR(32)): Dải địa chỉ IP gán cho vùng mạng.
- `session_timeout` (INT): Thời gian tối đa của phiên (giây).
- `idle_timeout` (INT): Thời gian rảnh tối đa (giây).
- `priority` (INT): Độ ưu tiên khi có xung đột nhóm.
- `description` (TEXT): Diễn giải quyền hạn và mục đích sử dụng.
- `is_active` (BOOLEAN): Trạng thái kích hoạt chính sách.
- `updated_at` (TIMESTAMP): Thời điểm cập nhật cuối cùng.

### 2. Bảng `radgroupreply` (Bảng chuẩn của FreeRADIUS SQL Module)
FreeRADIUS định kỳ hoặc theo từng truy vấn xác thực sẽ đọc bảng này để trích xuất các thuộc tính trả về thiết bị:
- `id` (INT, Primary Key)
- `groupname` (VARCHAR(64)): Tên nhóm (`quantri`, `giangvien`, v.v.).
- `attribute` (VARCHAR(64)): Tên thuộc tính RADIUS (`Tunnel-Type`, `Tunnel-Medium-Type`, `Tunnel-Private-Group-Id`, `Session-Timeout`).
- `op` (VARCHAR(2)): Toán tử gán (`=:` gán đè thuộc tính).
- `value` (VARCHAR(253)): Giá trị thuộc tính tương ứng.

> **Cơ chế đồng bộ tự động**: Khi Admin thay đổi VLAN ID trên Dashboard $\to$ Backend Flask cập nhật bảng `policy_matrix` đồng thời cập nhật dòng tương ứng trong `radgroupreply`. Lần đăng nhập tiếp theo, FreeRADIUS truy vấn SQL và nhận ngay VLAN ID mới!

---

## VI. LUỒNG XỬ LÝ PHÂN QUYỀN CHI TIẾT (AUTHORIZATION WORKFLOW)

```text
[Thiết bị / radtest] 
       │ 1. Gửi Access-Request (Username/Password)
       ▼
[FreeRADIUS Server]
       │ 2. Xác thực credentials qua OpenLDAP (Authenticate)
       ▼
[OpenLDAP Directory]
       │ 3. Trả về: Mật khẩu khớp + Danh sách nhóm (memberOf)
       ▼
[FreeRADIUS Server]
       │ 4. Kiểm tra nhóm:
       │    - Có thuộc nhóm 'quarantine'? ──[ĐÚNG]──► Lấy VLAN 99 (Override)
       │    - Không quarantine? ────────────────────► Chọn nhóm có Priority cao nhất
       │
       │ 5. Truy vấn SQL (radgroupreply / policy_matrix)
       ▼
[SQL Database]
       │ 6. Trả về bộ thuộc tính AVP:
       │    - Tunnel-Type = VLAN
       │    - Tunnel-Medium-Type = IEEE-802
       │    - Tunnel-Private-Group-Id = "<VLAN_ID>"
       │    - Session-Timeout = <Seconds>
       ▼
[FreeRADIUS Server]
       │ 7. Đóng gói phản hồi Access-Accept
       ▼
[Thiết bị / radtest]
       ◄── Nhận Access-Accept + Thuộc tính VLAN tương ứng
```
