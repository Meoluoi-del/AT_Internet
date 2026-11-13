# TÀI LIỆU THIẾT KẾ NGÀY 1: PHẠM VI DỰ ÁN & ĐẶC TẢ USER STORIES

> **Dự án**: Quản lý truy cập mạng và xác thực trung tâm (NAC & Centralized Authentication)  
> **Môn học**: An toàn mạng - PTITHCM  
> **Phiên bản**: 1.0 (Ngày 1)  

---

## I. XÁC ĐỊNH PHẠM VI DỰ ÁN (PROJECT SCOPE)

### 1. Trong phạm vi (In-Scope)
- **Kiến trúc AAA tập trung**: Triển khai đầy đủ 3 trụ cột:
  - *Authentication*: Xác thực danh tính người dùng qua OpenLDAP (giao thức RADIUS / RFC 2865).
  - *Authorization*: Phân quyền truy cập động bằng cách gán thuộc tính VLAN (*Dynamic VLAN Assignment*) theo nhóm người dùng.
  - *Accounting*: Ghi nhận nhật ký phiên truy cập, thời gian đăng nhập/đăng xuất vào cơ sở dữ liệu SQL.
- **Thư mục danh tính OpenLDAP**: Lưu trữ cấu trúc tổ chức (OU), nhóm quyền (`sinhvien`, `giangvien`, `quantri`, `quarantine`), và tài khoản người dùng với mật khẩu băm an toàn.
- **Máy chủ FreeRADIUS**: Đóng vai trò máy chủ trung gian AAA kết nối giữa thiết bị mạng và OpenLDAP/SQL.
- **Giao diện Web Quản trị (Flask Dashboard)**:
  - Quản lý vòng đời tài khoản LDAP (tạo mới, sửa, xóa, khóa/mở khóa).
  - Quản trị ma trận chính sách ánh xạ Nhóm $\to$ VLAN.
  - Giám sát phiên truy cập thời gian thực và tra cứu log xác thực.
  - Phân quyền người dùng quản trị (RBAC): Phân biệt rõ vai trò `Admin` (toàn quyền) và `Auditor` (chỉ đọc).
- **Cơ chế phòng vệ chủ động (Active Defense)**: Tự động phát hiện tấn công dò mật khẩu (brute-force) và tự động cô lập tài khoản sang nhóm `quarantine` (VLAN 99).
- **Đóng gói & Triển khai**: Tự động hóa toàn bộ môi trường bằng `docker compose up -d`.

### 2. Ngoài phạm vi & Giới hạn giả lập (Out-of-Scope & Simulation Constraints)
- **Thiết bị phần cứng vật lý**: Không sử dụng Switch/Access Point phần cứng thật trong môi trường lab. Thay vào đó:
  - Sử dụng công cụ chuẩn `radtest` và `eapol_test` để đóng vai trò máy trạm khách (*Supplicant*) và thiết bị mạng (*NAS - Network Access Server*).
  - Việc "gán VLAN thành công" được chứng minh bằng thuộc tính trả về trong bản tin `Access-Accept` (`Tunnel-Type = VLAN`, `Tunnel-Medium-Type = IEEE-802`, `Tunnel-Private-Group-Id = <VLAN_ID>`).
- **Single Sign-On (SSO / Kerberos)**: Không triển khai code SSO hoàn chỉnh (vì vượt quá thời lượng 8 ngày); chỉ phân tích, so sánh lý thuyết và đề xuất làm hướng phát triển trong Chương 6 của báo cáo.

---

## II. ĐẶC TẢ CHI TIẾT 10 USER STORIES

Mỗi User Story được chuẩn hóa theo cấu trúc nghiệp vụ: **Vai trò (Actor) – Hành động (Action) – Giá trị mang lại (Value)** kèm theo **Điều kiện tiên quyết (Preconditions)** và **Tiêu chí nghiệm thu (Acceptance Criteria)**.

---

### NHÓM A: XÁC THỰC MẠNG & CẤP QUYỀN ĐỘNG (NETWORK ACCESS & DYNAMIC NAC)

#### 🔷 US01: Xác thực người dùng qua danh tính tập trung
- **Story**: Là một **End-User (người dùng cuối)**, tôi muốn đăng nhập mạng bằng tài khoản tập trung duy nhất của mình, để truy cập vào hệ thống mạng nội bộ mà không cần phải nhớ nhiều tài khoản khác nhau trên từng thiết bị.
- **Thuộc tính ATTT**: *Authenticity (Tính xác thực)*.
- **Điều kiện tiên quyết**: Tài khoản đã tồn tại trong OpenLDAP và đang ở trạng thái hoạt động (active).
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Khi người dùng gửi yêu cầu với username và mật khẩu chính xác $\to$ FreeRADIUS xác thực thành công qua LDAP và phản hồi gói tin `Access-Accept`.
  2. Khi người dùng nhập sai mật khẩu hoặc tài khoản không tồn tại $\to$ FreeRADIUS phản hồi `Access-Reject`.
  3. Mọi kết quả (thành công hoặc thất bại) đều được ghi nhận vào nhật ký xác thực (`radpostauth` / log hệ thống) kèm timestamp và địa chỉ nguồn.

#### 🔷 US02: Gán phân đoạn mạng (VLAN) động theo vai trò người dùng
- **Story**: Là một **End-User**, tôi muốn được tự động gán vào đúng phân đoạn mạng (VLAN) tương ứng với vai trò của mình ngay sau khi xác thực thành công, để tôi có thể sử dụng các tài nguyên được phép truy cập.
- **Thuộc tính ATTT**: *Authorization (Cấp quyền)*, *Network Segmentation (Phân đoạn mạng)*.
- **Điều kiện tiên quyết**: Tài khoản đã thuộc về một nhóm xác định (`sinhvien`, `giangvien`, `quantri`).
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Người dùng thuộc nhóm `sinhvien` $\to$ Gói `Access-Accept` kèm thuộc tính `Tunnel-Private-Group-Id = "20"`.
  2. Người dùng thuộc nhóm `giangvien` $\to$ Gói `Access-Accept` kèm thuộc tính `Tunnel-Private-Group-Id = "30"`.
  3. Người dùng thuộc nhóm `quantri` $\to$ Gói `Access-Accept` kèm thuộc tính `Tunnel-Private-Group-Id = "10"`.
  4. Người dùng không thuộc nhóm nào hoặc thông tin không hợp lệ $\to$ Từ chối hoặc gán vào VLAN mặc định/hạn chế.

---

### NHÓM B: QUẢN TRỊ DANH TÍNH & CHÍNH SÁCH (IDENTITY & POLICY ADMINISTRATION)

#### 🔷 US03: Quản lý vòng đời tài khoản trên Web Dashboard
- **Story**: Là một **Admin (Quản trị viên)**, tôi muốn có giao diện web để thêm, sửa, xóa tài khoản người dùng trên LDAP, để tôi quản lý danh tính nhanh chóng, tiện lợi mà không phải thao tác dòng lệnh phức tạp (`ldapmodify`, `ldapadd`).
- **Thuộc tính ATTT**: *Availability (Tính khả dụng)*, *Usability*.
- **Điều kiện tiên quyết**: Admin đã đăng nhập thành công vào Dashboard với quyền `Admin`.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Thêm user mới thành công trên Web $\to$ Dữ liệu xuất hiện ngay trên LDAP; dùng `radtest` kiểm tra đăng nhập được ngay lập tức.
  2. Sửa thông tin user (đổi họ tên, reset mật khẩu) $\to$ Dữ liệu LDAP được cập nhật, mật khẩu mới có hiệu lực ngay.
  3. Xóa user $\to$ Bản ghi bị gỡ khỏi LDAP; kiểm tra bằng `radtest` nhận ngay kết quả `Access-Reject`.

#### 🔷 US04: Thay đổi quyền truy cập mạng bằng gán nhóm
- **Story**: Là một **Admin**, tôi muốn gán hoặc chuyển đổi nhóm cho người dùng trực tiếp trên giao diện, để điều chỉnh phạm vi truy cập mạng của người dùng khi có sự thay đổi về vai trò.
- **Thuộc tính ATTT**: *Role-Based Access Control (RBAC)*.
- **Điều kiện tiên quyết**: Nhóm đích đã tồn tại trong hệ thống.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Admin chuyển người dùng từ nhóm `sinhvien` sang `giangvien` trên web $\to$ Thành viên nhóm trên LDAP được cập nhật ngay.
  2. Tại lần xác thực kế tiếp (`radtest`), RADIUS tự động cấp VLAN 30 thay vì VLAN 20 như trước đó, không cần khởi động lại dịch vụ.

#### 🔷 US05: Cập nhật ma trận chính sách mạng (Nhóm $\to$ VLAN)
- **Story**: Là một **Admin**, tôi muốn có thể chỉnh sửa cấu hình ánh xạ giữa Nhóm người dùng và VLAN ID trên web, để hệ thống linh hoạt thích ứng khi hạ tầng mạng của tổ chức tái cấu trúc.
- **Thuộc tính ATTT**: *Flexibility*, *Authorization Configuration*.
- **Điều kiện tiên quyết**: Bảng chính sách được lưu trữ trong CSDL có thể chỉnh sửa.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Admin đổi cấu hình: `sinhvien` chuyển từ VLAN 20 sang VLAN 25 trên Dashboard.
  2. Lần xác thực tiếp theo của bất kỳ sinh viên nào $\to$ FreeRADIUS lập tức trả về `Tunnel-Private-Group-Id = "25"`.

#### 🔷 US06: Mở khóa và phục hồi tài khoản bị cô lập
- **Story**: Là một **Admin**, tôi muốn xem danh sách các tài khoản đang bị cách ly (`quarantine`) và có nút bấm mở khóa (khôi phục), để hỗ trợ người dùng hợp lệ quay lại mạng sau khi đã xử lý xong sự cố (ví dụ: gõ nhầm mật khẩu).
- **Thuộc tính ATTT**: *Availability*, *Incident Recovery*.
- **Điều kiện tiên quyết**: Tài khoản đang nằm trong nhóm `quarantine`.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Giao diện hiển thị danh sách các tài khoản bị cách ly kèm lý do và thời gian.
  2. Khi Admin bấm "Mở khóa", hệ thống đưa user ra khỏi nhóm `quarantine`, chuyển về nhóm gốc và reset bộ đếm lần sai.
  3. Lần xác thực tiếp theo của user nhận lại đúng VLAN ban đầu (không còn là VLAN 99).

---

### NHÓM C: GIÁM SÁT, KIỂM TOÁN & TRÁCH NHIỆM GIẢI TRÌNH (AUDIT & ACCOUNTABILITY)

#### 🔷 US07: Kiểm toán viên tra cứu nhật ký truy cập mạng
- **Story**: Là một **Auditor (Cán bộ kiểm toán/Bảo mật)**, tôi muốn truy cập bảng điều khiển để theo dõi các phiên truy cập mạng đang hoạt động và lịch sử xác thực, để phục vụ công tác điều tra và đánh giá rủi ro an toàn mạng.
- **Thuộc tính ATTT**: *Accountability (Tính trách nhiệm)*, *Principle of Least Privilege*.
- **Điều kiện tiên quyết**: Auditor đăng nhập với tài khoản có vai trò `Auditor`.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Auditor xem được danh sách phiên kết nối, log Accept/Reject kèm bộ lọc thời gian và username.
  2. Trên giao diện của Auditor, **tất cả** các nút Thêm/Sửa/Xóa tài khoản hoặc đổi chính sách đều bị ẩn.
  3. Nếu cố tình gửi request API (POST/PUT/DELETE) bằng công cụ ngoài (Postman/curl) $\to$ Backend trả về lỗi `403 Forbidden`.

#### 🔷 US08: Ghi vết nhật ký thao tác quản trị (Admin Audit Logging)
- **Story**: Là một **Auditor / Trưởng phòng bảo mật**, tôi muốn hệ thống tự động ghi lại toàn bộ hoạt động của các Admin, để bảo đảm tính minh bạch, chống chối bỏ và quy trách nhiệm khi có sự cố.
- **Thuộc tính ATTT**: *Non-Repudiation (Chống chối bỏ)*, *Accountability*.
- **Điều kiện tiên quyết**: Bất kỳ thao tác thay đổi cấu hình nào diễn ra trên hệ thống.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Mọi hành động (thêm user, xóa user, đổi VLAN, mở khóa) đều sinh ra 1 bản ghi trong bảng `audit_logs`.
  2. Bản ghi bắt buộc chứa: `Timestamp`, `Actor (Admin nào thực hiện)`, `IP nguồn`, `Hành động`, `Chi tiết thay đổi (Giá trị cũ $\to$ Giá trị mới)`.
  3. Bảng `audit_logs` được thiết kế chỉ cho phép ghi (Append-only), không cho phép sửa/xóa qua giao diện.

---

### NHÓM D: PHÒNG VỆ CHỦ ĐỘNG & BẢO VỆ HỆ THỐNG QUẢN TRỊ (ACTIVE DEFENSE & HARDENING)

#### 🔷 US09: Tự động phát hiện brute-force và cô lập mạng
- **Story**: Là **Hệ thống phòng thủ mạng**, tôi muốn tự động phát hiện các hành vi dò quét mật khẩu và lập tức chuyển người dùng bị nghi vấn vào phân đoạn cách ly, để ngăn chặn nguy cơ xâm nhập trái phép vào vùng mạng nội bộ nhạy cảm.
- **Thuộc tính ATTT**: *Detection & Active Defense (Mô hình 3D - An toàn mạng PTIT)*.
- **Điều kiện tiên quyết**: Cơ chế giám sát đếm số lần xác thực thất bại từ log RADIUS.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Nếu một tài khoản nhập sai mật khẩu vượt ngưỡng quy định (ví dụ: quá 5 lần trong 3 phút) $\to$ Hệ thống kích hoạt cơ chế phòng vệ.
  2. Người dùng tự động bị chuyển sang nhóm `quarantine`.
  3. Ở lần xác thực kế tiếp (dù lúc này đã gõ đúng mật khẩu) $\to$ RADIUS chỉ cấp `Tunnel-Private-Group-Id = "99"` (VLAN cách ly).
  4. Hệ thống bắn cảnh báo nổi bật (Alert Banner) lên Dashboard quản trị.

#### 🔷 US10: Bảo vệ an toàn bảng điều khiển Web Dashboard
- **Story**: Là một **Admin**, tôi muốn cơ chế đăng nhập vào Dashboard quản trị được trang bị các biện pháp phòng vệ an ninh, để bảo vệ hệ thống đầu não không bị tin tặc chiếm quyền điều khiển.
- **Thuộc tính ATTT**: *Confidentiality*, *Integrity*, *Defense in Depth*.
- **Điều kiện tiên quyết**: Hệ thống xác thực cho trang Web Dashboard.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**:
  1. Mật khẩu tài khoản quản trị được băm bằng thuật toán an toàn (bcrypt/Argon2/SSHA), không bao giờ lưu plaintext.
  2. Nếu đăng nhập sai quá số lần quy định trên web $\to$ Khóa tạm thời tài khoản admin trong thời gian cố định (ví dụ: 15 phút).
  3. Phiên làm việc (Session) tự động hết hạn khi không hoạt động sau thời gian quy định (Session Timeout).
  4. Sử dụng cơ chế phòng chống CSRF (CSRF Token) cho toàn bộ các biểu mẫu thao tác.

---

## III. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS - NFR)

| Mã NFR | Tiêu chuẩn | Mô tả kỹ thuật |
| :--- | :--- | :--- |
| **NFR-SEC01** | Lưu trữ mật khẩu | Toàn bộ mật khẩu người dùng cuối trên OpenLDAP được băm bằng `{SSHA}`. Mật khẩu admin trên Dashboard được băm bằng `bcrypt`. |
| **NFR-SEC02** | An toàn đường truyền | Giao tiếp nội bộ giữa FreeRADIUS $\leftrightarrow$ LDAP hỗ trợ kênh bảo mật (StartTLS/LDAPS). Giao tiếp Dashboard qua HTTPS (tự ký ở môi trường lab). |
| **NFR-SEC03** | Bảo mật mã nguồn | Không hardcode mật khẩu, shared secret RADIUS trong mã nguồn Git; sử dụng biến môi trường qua file `.env`. |
| **NFR-OPS01** | Tự động hóa triển khai | Khởi động toàn bộ hạ tầng gồm 4 dịch vụ (OpenLDAP, FreeRADIUS, MySQL/PostgreSQL, Flask) chỉ bằng đúng **1 lệnh**: `docker compose up -d`. |
| **NFR-OBS01** | Khả năng quan sát | Dữ liệu log xác thực, log kế toán và audit log được định dạng chuẩn, cho phép tìm kiếm và truy vết tức thì. |
