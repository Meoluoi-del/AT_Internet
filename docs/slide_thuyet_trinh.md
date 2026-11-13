# ĐỀ CƯƠNG SLIDE THUYẾT TRÌNH BẢO VỆ ĐỒ ÁN AN TOÀN MẠNG
# ĐỀ TÀI: QUẢN LÝ TRUY CẬP MẠNG VÀ XÁC THỰC TRUNG TÂM (CENTRALIZED NAC & AAA)

---

### SLIDE 1: TRANG BÌA
- **Tên đề tài**: Quản lý truy cập mạng và xác thực trung tâm (Centralized Network Access Control & AAA)
- **Học viện**: Học viện Công nghệ Bưu chính Viễn thông (PTITHCM) - Khoa An toàn Thông tin
- **Môn học**: An toàn mạng
- **Giảng viên hướng dẫn**: ThS. Nguyễn Hữu Nguyên
- **Sinh viên thực hiện**: Nhóm nghiên cứu đồ án

---

### SLIDE 2: ĐẶT VẤN ĐỀ & BÀI TOÁN THỰC TẾ
- **Bối cảnh**: Tổ chức có hàng trăm người dùng và thiết bị mạng (Wi-Fi, VPN, switch, máy chủ).
- **Nguy cơ của quản trị phân tán (Decentralized)**:
  - Sinh viên ra trường hoặc nhân viên nghỉ việc nhưng tài khoản vẫn sót lại trên thiết bị $\to$ Lỗ hổng xâm nhập nguy hiểm.
  - Đổi mật khẩu hoặc phân quyền phải làm thủ công từng nơi $\to$ Dễ sai sót, thiếu nhất quán.
  - Mất khả năng kiểm toán: Không ai biết ai đã vào mạng lúc nào, ở đâu $\to$ Vi phạm tiêu chuẩn ISO 27001 / NIST.
- **Giải pháp**: Gom toàn bộ về một trung tâm duy nhất theo mô hình **AAA**.

---

### SLIDE 3: MỤC TIÊU CỐT LÕI CỦA ĐỒ ÁN
1. **Authentication (Xác thực)**: OpenLDAP đóng vai trò là "Nguồn sự thật duy nhất" (Single Source of Truth), lưu trữ danh tính và mật khẩu băm SSHA.
2. **Authorization (Cấp quyền)**: FreeRADIUS tự động gán phân đoạn mạng động (**Dynamic VLAN**) theo vai trò người dùng (RFC 2868 / RFC 3580).
3. **Accounting (Ghi nhận)**: Ghi lại toàn bộ phiên kết nối và nhật ký xác thực vào cơ sở dữ liệu SQL.
4. **Active Defense (Phòng vệ chủ động)**: Tự động phát hiện tấn công dò mật khẩu (brute-force) và lập tức cô lập vào VLAN 99.
5. **Giao diện quản trị hiện đại**: Flask Web Dashboard phân quyền Admin (toàn quyền) và Auditor (chỉ đọc).

---

### SLIDE 4: KIẾN TRÚC HỆ THỐNG TỔNG THỂ (CONTAINERIZED ARCHITECTURE)
- **Mạng nội bộ cô lập**: `nac-net` (Docker Bridge Network).
- **Cụm 4 Microservices**:
  - `nac_ldap`: Cổng 389 (OpenLDAP 1.5).
  - `nac_mariadb`: Cổng 3306 (MariaDB 10.11).
  - `nac_radius`: Cổng 1812, 1813 UDP (FreeRADIUS 3.2).
  - `nac_dashboard`: Cổng 5000 HTTP (Flask Application).
- **Khởi động**: Chỉ bằng 1 câu lệnh duy nhất `docker compose up -d`.

---

### SLIDE 5: THIẾT KẾ CÂY THƯ MỤC OPENLDAP (DIT)
- **Gốc thư mục**: `dc=attt,dc=ptit,dc=edu,dc=vn`
- **Các Đơn vị tổ chức (OU)**:
  - `ou=users`: Chứa tài khoản người dùng (`admin01`, `gv_nguyen`, `sv_an`, `sv_binh`, `sv_test`).
  - `ou=groups`: Chứa các nhóm vai trò (`quantri`, `giangvien`, `sinhvien`, `quarantine`).
  - `ou=services`: Chứa tài khoản dịch vụ chỉ đọc `cn=radius-svc` (Tuân thủ nguyên tắc Đặc quyền tối thiểu - Least Privilege).
- **Bảo mật mật khẩu**: Toàn bộ mật khẩu được băm dạng `{SSHA}` với muối 4-byte ngẫu nhiên chống tấn công Rainbow Table.

---

### SLIDE 6: MA TRẬN PHÂN QUYỀN DYNAMIC VLAN (RFC 2868 / 3580)
- **Cơ chế**: Gói `Access-Accept` mang theo bộ 3 thuộc tính:
  - `Tunnel-Type = VLAN (13)`
  - `Tunnel-Medium-Type = IEEE-802 (6)`
  - `Tunnel-Private-Group-Id = <VLAN_ID>`
- **Bảng phân quyền thực tế**:
  - **`quantri`** $\to$ **VLAN 10**: Toàn quyền quản trị mạng nội bộ, timeout 2h.
  - **`giangvien`** $\to$ **VLAN 30**: Nghiệp vụ đào tạo, LMS, máy chủ điểm, timeout 8h.
  - **`sinhvien`** $\to$ **VLAN 20**: Cổng đào tạo sinh viên, Internet học tập, timeout 4h.
  - **`quarantine`** $\to$ **VLAN 99**: Cách ly tuyệt đối, chỉ vào web đổi mật khẩu, timeout 30m.
- **Quy tắc giải quyết xung đột**: Nhóm `quarantine` luôn có độ ưu tiên cao nhất (Priority 1000) ghi đè mọi quyền khác.

---

### SLIDE 7: CƠ CHẾ PHÒNG VỆ CHỦ ĐỘNG (ACTIVE DEFENSE WORKER)
- **Áp dụng mô hình 3D**: Phòng ngừa - Phát hiện - Răn đe/Phản ứng.
- **Quy trình hoạt động**:
  1. Kẻ tấn công thử sai mật khẩu liên tiếp $\to$ FreeRADIUS ghi log Reject vào `radpostauth`.
  2. Detector ngầm quét định kỳ 10 giây/lần: Nếu $\ge 5$ lần sai trong 3 phút $\to$ BẬT BÁO ĐỘNG.
  3. Hệ thống tự động chuyển user sang nhóm `quarantine` trên OpenLDAP.
  4. Ghi nhận sự kiện vào `audit_logs` với actor `SYSTEM_ACTIVE_DEFENSE`.
  5. Lần tiếp theo dù gõ đúng mật khẩu, RADIUS vẫn ép nhận **VLAN 99**!

---

### SLIDE 8: GIAO DIỆN QUẢN TRỊ FLASK & PHÂN QUYỀN RBAC
- **Phân tách vai trò nghiêm ngặt**:
  - **Admin** (`admin`): Thêm/xóa user LDAP, chỉnh sửa VLAN trong policy matrix, mở khóa tài khoản bị cách ly.
  - **Auditor** (`auditor`): Xem nhật ký xác thực, xem phiên trực tuyến, xem audit log. Mọi nút sửa/xóa bị ẩn và chặn API ở tầng Backend với lỗi `403 Forbidden`.
- **Tính năng nổi bật**:
  - Tự động đồng bộ giữa bảng `policy_matrix` và bảng `radgroupreply` của FreeRADIUS.
  - Cảnh báo trực quan Banner đỏ khi phát hiện brute-force.
  - Hỗ trợ đa phiên độc lập trên từng Tab trình duyệt (`TabSessionInterface`).
  - Bảng Audit Log chỉ cho phép ghi (Append-Only) chống chối bỏ.

---

### SLIDE 9: MỞ RỘNG BẢO MẬT: XÁC THỰC ĐA NHÂN TỐ (MFA) & SINGLE SIGN-ON (SSO)
- **Xác thực Đa nhân tố (MFA / 2FA TOTP RFC 6238)**:
  - Sinh mã biến thiên 30s tương thích **Google Authenticator**, **Microsoft Authenticator**, **Authy**.
  - Cơ chế quét mã QR và xác thực 2 bước (Two-Step Verification) cho tài khoản quản trị mạng.
- **Mở rộng Single Sign-On (SSO) chuẩn OAuth 2.0 & OpenID Connect (OIDC)**:
  - **OpenID Discovery**: Endpoint chuẩn quốc tế `/.well-known/openid-configuration`.
  - **Cổng SSO Launchpad**: Đăng nhập 1 lần, truy cập 1-chạm 5 ứng dụng nội bộ PTIT (QLĐT/LMS, Thư viện E-Library, VPN Gateway, Webmail, NAC Console).
  - **Cấp phát JWT Token (RFC 7519)**: Token ký số HMAC-SHA256 chứa đầy đủ Claim phân quyền mạng VLAN và nhóm người dùng.

---

### SLIDE 10: KỊCH BẢN DEMO THỰC TẾ (3 - 5 PHÚT)
1. **Demo 1**: Đăng nhập `sv_an` $\to$ Nhận `Access-Accept` kèm **VLAN 20**.
2. **Demo 2**: Đăng nhập `gv_nguyen` $\to$ Nhận `Access-Accept` kèm **VLAN 30**.
3. **Demo 3**: Đổi cấu hình `sinhvien` từ VLAN 20 sang VLAN 25 trên Web $\to$ Xác thực lại nhận ngay **VLAN 25** (không cần restart RADIUS!).
4. **Demo 4**: Chạy script tấn công Brute-force 6 lần trên `sv_test` $\to$ Hệ thống tự động đẩy vào `quarantine` $\to$ Đăng nhập lại với pass đúng vẫn nhận **VLAN 99**!
5. **Demo 5**: Admin bấm nút "Mở khóa" trên Dashboard $\to$ Phục hồi tài khoản về VLAN ban đầu.

---

### SLIDE 10: ĐÁNH GIÁ AN TOÀN VÀ PHÒNG CHỐNG TẤN CÔNG
- **Chống Brute-force**: Cơ chế Active Defense tự động cô lập.
- **Chống Sniffing**: Mật khẩu băm SSHA, RADIUS MD5 XOR, sẵn sàng cho EAP-TLS.
- **Chống Rogue AP**: 802.1X xác thực 2 chiều thông qua chứng chỉ số máy chủ.
- **Chống Injection (SQLi/LDAPi)**: Parameterized queries và thư viện ldap3 escaping.
- **Chống CSRF / Chiếm session**: Cờ HttpOnly, SameSite, Session Timeout.
- **Chống lạm quyền Admin**: Bảng Audit Log Append-Only truy vết mọi hành vi.

---

### SLIDE 11: KẾT LUẬN & HƯỚNG MỞ RỘNG
- **Kết quả đạt được**: Hoàn thành 100% mục tiêu đề tài, hệ thống hoạt động ổn định, có bằng chứng log và kiểm thử tự động.
- **Hướng phát triển tương lai**:
  - Tích hợp xác thực đa nhân tố (MFA - OTP / Google Authenticator).
  - Mở rộng Single Sign-On (SSO / Kerberos / SAML / OIDC) với Keycloak.
  - Tích hợp giao thức TACACS+ cho thiết bị định tuyến viễn thông.

---

### SLIDE 12: HỎI & ĐÁP (Q&A) - GỢI Ý CÂU HỎI PHẢN BIỆN
- **Câu 1: Vì sao không tự code một máy chủ RADIUS từ đầu mà dùng FreeRADIUS?**  
  *Trả lời*: RADIUS là chuẩn giao thức phức tạp (RFC 2865, 2866, EAP-TLS). FreeRADIUS là giải pháp máy chủ chuẩn mực công nghiệp toàn cầu, đã được kiểm chứng an ninh hàng chục năm. Việc tận dụng FreeRADIUS và tập trung xây dựng cơ chế NAC, logic phân quyền động và Web Dashboard là cách tiếp cận kỹ thuật chuyên nghiệp nhất.
- **Câu 2: OpenLDAP khác gì với Active Directory?**  
  *Trả lời*: Active Directory là giải pháp trọn gói độc quyền của Microsoft. OpenLDAP là chuẩn mở gọn nhẹ, chỉ tập trung vào thư mục danh tính phân cấp, dễ dàng đóng gói trong microservices Docker và không phát sinh chi phí bản quyền.
- **Câu 3: Làm thế nào chứng minh VLAN được áp dụng khi không có Switch thật?**  
  *Trả lời*: Theo RFC 3580, nhiệm vụ cốt lõi của máy chủ AAA là ra quyết định và gửi bộ 3 thuộc tính `Tunnel-Type`, `Tunnel-Medium-Type`, `Tunnel-Private-Group-Id` trong gói `Access-Accept`. Thiết bị switch chỉ việc đọc thuộc tính này để chuyển cổng vật lý. Đồ án đã chứng minh gói tin trả về mang chính xác các trường dữ liệu này.
