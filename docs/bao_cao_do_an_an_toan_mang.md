# BÁO CÁO ĐỒ ÁN MÔN HỌC: AN TOÀN MẠNG
# ĐỀ TÀI: QUẢN LÝ TRUY CẬP MẠNG VÀ XÁC THỰC TRUNG TÂM (CENTRALIZED NAC & AAA)

> **Học viện Công nghệ Bưu chính Viễn thông (PTITHCM)**  
> **Khoa An toàn Thông tin**  
> **Môn học**: An toàn mạng  
> **Giảng viên hướng dẫn**: ThS. Nguyễn Hữu Nguyên  
> **Năm học**: 2026 - 2027  

---

## CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI

### 1.1. Bối cảnh và Bài toán thực tế
Trong kỷ nguyên chuyển đổi số, hạ tầng mạng của các tổ chức giáo dục và doanh nghiệp ngày càng mở rộng với hàng nghìn thiết bị đầu cuối kết nối đa dạng: máy tính cán bộ, laptop sinh viên, thiết bị di động cá nhân (BYOD), máy in, và các thiết bị IoT. 

Nếu một tổ chức áp dụng mô hình quản trị tài khoản phân tán (Decentralized Authentication) — tức là cấu hình tài khoản cục bộ trên từng Access Point, Router, VPN Gateway, hoặc máy chủ — sẽ đối mặt với các nguy cơ an toàn thông tin nghiêm trọng:
1. **Lỗ hổng thu hồi quyền truy cập (Dangling Accounts)**: Khi sinh viên tốt nghiệp hoặc nhân viên nghỉ việc, quản trị viên dễ bỏ sót tài khoản trên một số thiết bị mạng, tạo điều kiện cho tin tặc lợi dụng các tài khoản "mồ côi" này để xâm nhập nội bộ.
2. **Thiếu tính nhất quán của chính sách (Policy Inconsistency)**: Khi cần thay đổi chính sách phân đoạn mạng hoặc đổi mật khẩu, việc thao tác thủ công trên từng thiết bị gây lãng phí nhân lực và phát sinh sai sót kỹ thuật.
3. **Mất khả năng kiểm toán và truy vết (Lack of Accountability)**: Không có nhật ký tập trung để xác định "Ai đã vào mạng, vào lúc nào, tại vị trí nào, và đã thực hiện những gì", vi phạm trực tiếp các tiêu chuẩn an toàn thông tin quốc tế (ISO 27001, NIST SP 800-53).

### 1.2. Mục tiêu nghiên cứu và giải pháp đề xuất
Đề tài hướng tới việc giải quyết triệt để bài toán trên bằng cách xây dựng hệ thống **Kiểm soát truy cập mạng (Network Access Control - NAC)** và **Xác thực trung tâm** dựa trên khung kiến trúc **AAA (Authentication, Authorization, Accounting)**:
- **Xác thực tập trung (Authentication)**: Đưa toàn bộ danh tính người dùng về một Thư mục duy nhất (**OpenLDAP**) đóng vai trò là "Nguồn sự thật duy nhất" (*Single Source of Truth*).
- **Cấp quyền động theo vai trò (Dynamic Authorization)**: Sử dụng máy chủ **FreeRADIUS** kết hợp giao thức IEEE 802.1X/RADIUS để tự động gán người dùng vào các phân đoạn mạng (**Dynamic VLAN Assignment**) dựa trên vai trò (`sinhvien`, `giangvien`, `quantri`).
- **Ghi nhận kiểm toán (Accounting)**: Tự động ghi lại thời gian bắt đầu, kết thúc, địa chỉ IP và lưu lượng của từng phiên truy cập vào cơ sở dữ liệu SQL.
- **Phòng vệ chủ động (Active Defense)**: Tự động phát hiện tấn công dò mật khẩu (Brute-force) và lập tức cô lập đối tượng vi phạm vào phân đoạn mạng cách ly (`quarantine` - VLAN 99).
- **Giao diện quản trị hiện đại (Flask Dashboard)**: Cung cấp Web UI trực quan cho Quản trị viên (Admin) và Cán bộ kiểm toán (Auditor) với cơ chế phân quyền RBAC nghiêm ngặt.

### 1.3. Phạm vi và Giới hạn giả lập
- **Trong phạm vi**: Xây dựng toàn bộ cụm dịch vụ ảo hóa trên Docker (OpenLDAP, FreeRADIUS, MariaDB, Flask Dashboard); hiện thực hóa đầy đủ 3 trụ cột AAA; thực hiện gán Dynamic VLAN theo chuẩn RFC 2868 và RFC 3580; xây dựng cơ chế tự động phòng vệ brute-force; kiểm thử tự động với công cụ chuyên dụng.
- **Giới hạn giả lập**: Do điều kiện phòng lab không trang bị Switch L2/L3 vật lý và Access Point doanh nghiệp, việc gán VLAN được chứng minh bằng việc FreeRADIUS trả về chính xác bộ 3 thuộc tính AVP (`Tunnel-Type`, `Tunnel-Medium-Type`, `Tunnel-Private-Group-Id`) trong bản tin `Access-Accept`. Thiết bị khách được giả lập thông qua các công cụ chuẩn mạng (`radtest` và bộ script socket RADIUS).

---

## CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÁC TIÊU CHUẨN AN TOÀN

### 2.1. Khung kiến trúc AAA (Authentication - Authorization - Accounting)
AAA là nền tảng cốt lõi trong bảo mật mạng máy tính:
- **Authentication (Xác thực)**: Trả lời câu hỏi *"Bạn là ai?"*. Hệ thống đối chiếu thông tin định danh (Username) và bằng chứng xác thực (Mật khẩu, Chứng chỉ số) với cơ sở dữ liệu người dùng.
- **Authorization (Cấp quyền)**: Trả lời câu hỏi *"Bạn được phép làm gì và ở đâu?"*. Sau khi xác thực thành công, hệ thống xác định các đặc quyền mạng tương ứng với vai trò của người dùng (ví dụ: VLAN ID, Access Control List, thời lượng phiên).
- **Accounting (Ghi nhận/Kiểm toán)**: Trả lời câu hỏi *"Bạn đã làm gì và chiếm dụng tài nguyên bao lâu?"*. Hệ thống thu thập dữ liệu thống kê phiên truy cập phục vụ quản lý băng thông và điều tra sự cố số (*Digital Forensics*).

### 2.2. Giao thức RADIUS và chuẩn Dynamic VLAN
RADIUS (*Remote Authentication Dial-In User Service* - RFC 2865, RFC 2866) là giao thức hoạt động theo mô hình Client/Server sử dụng tầng vận chuyển UDP (cổng 1812 cho Authentication/Authorization và 1813 cho Accounting):
- **Bản tin Access-Request**: Do thiết bị mạng (NAS) gửi tới RADIUS server mang thông tin xác thực của người dùng.
- **Bản tin Access-Accept**: RADIUS server gửi lại NAS khi xác thực thành công, chứa các thuộc tính phân quyền mạng.
- **Bản tin Access-Reject**: RADIUS server từ chối yêu cầu truy cập khi sai thông tin hoặc bị khóa tài khoản.

Để thực hiện **Dynamic VLAN Assignment (DVA)**, bản tin `Access-Accept` chứa bộ 3 thuộc tính đường hầm theo chuẩn **RFC 2868** và **RFC 3580**:
1. `Tunnel-Type = VLAN (13)`: Chỉ định loại đường hầm là phân đoạn mạng logic 802.1Q.
2. `Tunnel-Medium-Type = IEEE-802 (6)`: Chỉ định môi trường truyền dẫn là mạng cục bộ Ethernet / Wi-Fi.
3. `Tunnel-Private-Group-Id = "<VLAN_ID>"`: Chỉ định mã VLAN thẻ (ví dụ: "10", "20", "30", "99").

### 2.3. Thư mục danh tính LDAP (Lightweight Directory Access Protocol)
LDAP (RFC 4511) là giao thức chuẩn mở tối ưu hóa cho thao tác đọc và tra cứu thông tin danh tính phân cấp:
- Cấu trúc cây thông tin danh tính (**DIT - Directory Information Tree**) bắt đầu từ gốc (*Base DN*), phân nhánh thành các Đơn vị tổ chức (*Organizational Units - OU*) và các mục danh mục (*Entries*).
- Mỗi mục danh mục được xác định bằng một định danh duy nhất (**Distinguished Name - DN**).
- Mật khẩu được băm bằng thuật toán an toàn **SSHA (Salted SHA-1)**, kết hợp muối ngẫu nhiên để vô hiệu hóa hoàn toàn hình thức tấn công bằng bảng cầu vồng (*Rainbow Table*).

### 2.4. So sánh kỹ thuật
- **RADIUS vs TACACS+**: RADIUS kết hợp Authentication và Authorization trong một gói tin và mã hóa chỉ trường mật khẩu; TACACS+ (Cisco) tách biệt 3 chức năng và mã hóa toàn bộ thân gói tin TCP. RADIUS được chọn vì là chuẩn mở quốc tế tương thích rộng rãi với mọi thiết bị mạng và giải pháp mã nguồn mở.
- **LDAP vs Microsoft Active Directory**: Active Directory là giải pháp độc quyền của Microsoft xây dựng trên nền tảng Kerberos + LDAP. OpenLDAP là giải pháp mã nguồn mở linh hoạt, tiêu tốn ít tài nguyên, lý tưởng cho môi trường container hóa Docker.

---

## CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

### 3.1. Phân tích rủi ro định lượng (ALE = SLE x ARO)
Theo phương pháp luận quản lý rủi ro trong Chương 1 môn An toàn mạng, nhóm nghiên cứu đánh giá rủi ro cho bài toán quản lý truy cập phân tán:
- **Tài sản cần bảo vệ**: Cơ sở dữ liệu điểm thi, tài liệu nghiên cứu khoa học, hệ thống máy chủ mạng nội bộ. Giá trị tài sản ước tính: **\$100,000**.
- **Mối đe dọa**: Tin tặc hoặc người dùng không có thẩm quyền truy cập trái phép qua tài khoản cũ hoặc mạng Wi-Fi sinh viên để tấn công nội bộ.
- **Tỷ lệ phơi nhiễm (Exposure Factor - EF)**: Ước tính 40%.
- **Tổn thất đơn lẻ (Single Loss Expectancy - SLE)**:
  $$SLE = \text{Asset Value} \times EF = \$100,000 \times 40\% = \$40,000$$
- **Tần suất xảy ra hàng năm (Annualized Rate of Occurrence - ARO)**: Ước tính 0.5 (xảy ra 1 lần trong 2 năm).
- **Tổn thất kỳ vọng hàng năm (Annualized Loss Expectancy - ALE)**:
  $$ALE = SLE \times ARO = \$40,000 \times 0.5 = \$20,000/\text{năm}$$
- **Hiệu quả của giải pháp NAC tập trung**: Triển khai hệ thống NAC tập trung với chi phí đầu tư hạ tầng phần mềm mã nguồn mở gần như bằng 0, giảm xác suất sự cố xuống mức tối thiểu, mang lại giá trị kinh tế và an toàn thông tin vượt bậc.

### 3.2. Đặc tả bộ 10 User Stories
Hệ thống đáp ứng trọn vẹn 10 kịch bản người dùng (US01 $\to$ US10):
- **US01**: Đăng nhập mạng bằng tài khoản tập trung duy nhất (`Access-Accept` khi đúng, `Access-Reject` khi sai).
- **US02**: Tự động nhận đúng VLAN theo vai trò (Sinh viên $\to$ VLAN 20, Giảng viên $\to$ VLAN 30, Quản trị $\to$ VLAN 10).
- **US03**: Quản lý vòng đời tài khoản LDAP trực tiếp trên Web Dashboard mà không cần gõ lệnh.
- **US04**: Thay đổi quyền mạng tức thì bằng cách chuyển nhóm người dùng trên giao diện.
- **US05**: Cập nhật ma trận chính sách mạng (Nhóm $\to$ VLAN) có hiệu lực ở lần xác thực tiếp theo mà không cần khởi động lại dịch vụ.
- **US06**: Mở khóa và phục hồi tài khoản bị cách ly trở lại mạng bình thường.
- **US07**: Cán bộ kiểm toán (Auditor) tra cứu nhật ký xác thực nhưng bị chặn toàn bộ thao tác chỉnh sửa.
- **US08**: Tự động ghi nhật ký thao tác quản trị (Audit Log) theo cơ chế chỉ cho phép ghi (Append-Only).
- **US09**: Tự động phát hiện tấn công brute-force (quá 5 lần sai trong 3 phút) và cách ly vào VLAN 99.
- **US10**: Bảo vệ bảng điều khiển quản trị bằng phân quyền RBAC và kiểm soát phiên làm việc.

### 3.3. Thiết kế Cây thư mục LDAP (DIT)
Gốc thư mục: `dc=attt,dc=ptit,dc=edu,dc=vn`
- `ou=users`: Chứa các tài khoản người dùng (`admin01`, `gv_nguyen`, `sv_an`, `sv_binh`, `sv_test`) theo chuẩn `inetOrgPerson`.
- `ou=groups`: Chứa các nhóm phân quyền (`quantri`, `giangvien`, `sinhvien`, `quarantine`) theo chuẩn `groupOfNames`.
- `ou=services`: Chứa tài khoản dịch vụ chỉ đọc `cn=radius-svc` phục vụ kết nối an toàn từ FreeRADIUS.
- `ou=policies`: Nhánh mở rộng lưu trữ chính sách.

### 3.4. Ma trận chính sách phân quyền mạng (Policy Matrix)

| Nhóm LDAP | VLAN ID | Tên phân đoạn | Dải IP CIDR | Session Timeout | Idle Timeout | Quyền hạn mạng |
| :--- | :---: | :--- | :--- | :---: | :---: | :--- |
| **`quantri`** | **10** | VLAN Quản trị | `10.10.10.0/24` | 7.200s *(2h)* | 900s | Toàn quyền quản trị máy chủ và hạ tầng |
| **`giangvien`** | **30** | VLAN Giảng viên | `10.10.30.0/24` | 28.800s *(8h)* | 1.800s | Cổng đào tạo, LMS, máy chủ nhập điểm |
| **`sinhvien`** | **20** | VLAN Sinh viên | `10.10.20.0/24` | 14.400s *(4h)* | 600s | Cổng thông tin đào tạo, Internet học tập |
| **`quarantine`** | **99** | VLAN Cách ly | `10.10.99.0/24` | 1.800s *(30m)* | 300s | Bị cô lập, chỉ truy cập trang đổi mật khẩu |

---

## CHƯƠNG 4: TRIỂN KHAI VÀ HIỆN THỰC HÓA HỆ THỐNG

### 4.1. Kiến trúc Microservices trên Docker Compose
Toàn bộ hệ thống được đóng gói thành 4 container kết nối thông qua mạng nội bộ cô lập `nac-net`:
1. `nac_ldap` (`osixia/openldap:1.5.0`): Tự động nạp file `ldap/init-ldap.ldif` khi khởi tạo.
2. `nac_mariadb` (`mariadb:10.11`): Tự động nạp schema và chính sách từ `sql/init-policy.sql`.
3. `nac_radius` (`freeradius/freeradius-server` tùy biến): Cấu hình nạp module `ldap` và `sql`, ánh xạ dynamic VLAN unlang.
4. `nac_dashboard` (Python 3.10 Flask): Chạy ứng dụng quản trị trung tâm và tiến trình ngầm Active Defense Detector.

Toàn bộ hệ thống được khởi động bằng đúng 1 câu lệnh duy nhất:
```bash
docker compose up -d --build
```

### 4.2. Hiện thực hóa cơ chế Dynamic VLAN trên FreeRADIUS
Trong file `radius/sites-available/default`, nhóm nghiên cứu áp dụng ngôn ngữ cấu hình Unlang để xử lý phân quyền động:
```unlang
if (LDAP-Group == "quarantine") {
    update reply {
        Tunnel-Type := VLAN
        Tunnel-Medium-Type := IEEE-802
        Tunnel-Private-Group-Id := "%{%{sql:SELECT vlan_id FROM policy_matrix WHERE group_name = 'quarantine' AND is_active = 1 LIMIT 1}:-99}"
        Session-Timeout := 1800
        Idle-Timeout := 300
        Termination-Action := 1
    }
}
elsif (LDAP-Group == "quantri") {
    update reply {
        Tunnel-Type := VLAN
        Tunnel-Medium-Type := IEEE-802
        Tunnel-Private-Group-Id := "%{%{sql:SELECT vlan_id FROM policy_matrix WHERE group_name = 'quantri' AND is_active = 1 LIMIT 1}:-10}"
        Session-Timeout := 7200
    }
}
...
```
Cấu hình trên mang tính đột phá: Giá trị VLAN ID được truy vấn trực tiếp từ bảng `policy_matrix` trong CSDL MariaDB. Khi Admin đổi số VLAN trên Web Dashboard, FreeRADIUS sẽ tự động áp dụng VLAN mới ngay trong lần xác thực kế tiếp mà không cần khởi động lại dịch vụ!

### 4.3. Hiện thực hóa cơ chế Phòng vệ chủ động (Active Defense)
Tiến trình ngầm `dashboard/detector.py` chạy chu kỳ quét 10 giây/lần:
```sql
SELECT username, COUNT(*) as failed_count 
FROM radpostauth 
WHERE reply = 'Access-Reject' AND authdate >= NOW() - INTERVAL 180 SECOND 
GROUP BY username HAVING failed_count >= 5;
```
Khi phát hiện tài khoản vượt quá 5 lần đăng nhập sai:
1. Gọi module `ldap_client.quarantine_user(username)` để gỡ user khỏi nhóm cũ và chuyển vào nhóm `quarantine`.
2. Ghi một bản ghi vào bảng `audit_logs` với actor `SYSTEM_ACTIVE_DEFENSE`.
3. Đẩy cảnh báo lên giao diện Web Dashboard.
4. Lần tiếp theo dù người dùng nhập đúng mật khẩu, FreeRADIUS vẫn chỉ trả về **VLAN 99 (Cách ly)**!

### 4.4. Hiện thực hóa Xác thực Đa nhân tố (MFA / 2FA TOTP RFC 6238)
Để đáp ứng tiêu chuẩn an toàn cấp cao cho tài khoản quản trị mạng, hệ thống đã mở rộng cơ chế Xác thực đa nhân tố (Multi-Factor Authentication - MFA):
1. **Thuật toán sinh mã OTP thời gian thực**: Sử dụng chuẩn công nghiệp **RFC 6238 (TOTP)** kết hợp **HMAC-SHA1** trên khóa bí mật 160-bit dạng Base32 (RFC 4648). Mã biến thiên ngẫu nhiên theo chu kỳ 30 giây, tương thích hoàn hảo với **Google Authenticator**, **Microsoft Authenticator** và **Authy**.
2. **Quy trình kích hoạt & Quét mã QR**: Cung cấp giao diện Web trực quan hiển thị mã QR `otpauth://totp/...`. Người dùng quét mã trên điện thoại và nhập mã xác thực 6 số đầu tiên để kích hoạt bảo vệ.
3. **Cơ chế xác thực 2 bước (Two-Step Verification)**: Khi tài khoản đã bật MFA, việc nhập đúng mật khẩu ở Bước 1 sẽ tự động điều hướng sang Bước 2 (`/mfa/verify`). Người dùng bắt buộc phải cung cấp mã TOTP 6 số hợp lệ mới được cấp phiên làm việc.

### 4.5. Mở rộng Hệ thống Single Sign-On (SSO) và chuẩn OpenID Connect / OAuth 2.0
Nhằm giải quyết bài toán "Một lần đăng nhập, vạn dịch vụ tin cậy", đồ án đã phát triển mở rộng tầng **Identity Provider (IdP)** hỗ trợ chuẩn **OAuth 2.0** và **OpenID Connect (OIDC)**:
1. **Discovery Endpoint chuẩn quốc tế**: Cung cấp endpoint `/.well-known/openid-configuration` (RFC 8414) công khai siêu dữ liệu về Token Endpoint, UserInfo Endpoint, thuật toán ký số và các scope danh tính.
2. **Cổng SSO Tập trung (Unified SSO Launchpad)**: Cổng thông tin tại `/sso/portal` liên kết 5 dịch vụ cốt lõi trong trường đại học:
   - Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)
   - Thư viện Số & Học liệu chuyên ngành (E-Library)
   - Cổng Truy cập Từ xa (Zero-Trust VPN Gateway)
   - Hệ thống Thư điện tử Sinh viên & Cán bộ (Webmail)
   - Bảng điều khiển Quản trị mạng Trung tâm (NAC Console)
3. **Cấp phát JWT Token chuẩn RFC 7519**: Sau khi người dùng xác thực thành công qua SSO, hệ thống cấp phát mã ủy quyền (*Authorization Code*) và đổi lấy cặp **JWT Access Token & ID Token** được ký số bằng thuật toán **HMAC-SHA256**. Token chứa đầy đủ các Claim định danh (`sub`, `name`, `email`, `group`, `vlan`), cho phép các ứng dụng vệ tinh tự động nhận diện phân đoạn mạng người dùng mà không cần nhập lại mật khẩu.

---

## CHƯƠNG 5: ĐÁNH GIÁ AN TOÀN VÀ PHÒNG NGỪA TẤN CÔNG

| Mối đe dọa an toàn | Kỹ thuật tấn công của Hacker | Giải pháp phòng ngự được áp dụng trong đồ án |
| :--- | :--- | :--- |
| **Dò quét mật khẩu (Brute-Force)** | Dùng từ điển tấn công liên tục vào cổng xác thực mạng 802.1X | **Active Defense**: Tự động phát hiện khi sai quá 5 lần/3 phút, lập tức chuyển sang nhóm `quarantine` (VLAN 99). |
| **Đánh cắp mật khẩu Admin (Credential Theft)** | Tin tặc lấy được mật khẩu quản trị qua phishing hoặc keylogger | **Xác thực Đa nhân tố (MFA TOTP)**: Đòi hỏi mã OTP 6 số ngẫu nhiên trên thiết bị vật lý; biết mật khẩu vẫn không thể đăng nhập. |
| **Đăng nhập phân tán nhiều ứng dụng (SSO Hijacking)** | Giả mạo yêu cầu đăng nhập vào các ứng dụng nội bộ | **OAuth 2.0 & OIDC**: Cơ chế Authorization Code kết hợp Secret Key; Token JWT ký số HMAC-SHA256 có thời hạn (exp). |
| **Nghe lén mật khẩu trên mạng (Sniffing)** | Dùng Wireshark bắt gói tin truyền mật khẩu dạng rõ | Mật khẩu lưu trữ băm SSHA; giao thức RADIUS mã hóa trường mật khẩu bằng MD5 XOR; hỗ trợ đường hầm EAP-TLS. |
| **Thiết bị phát Wi-Fi giả mạo (Rogue AP)** | Dựng AP mạo danh (Evil Twin) để đánh cắp danh tính sinh viên | Giao thức 802.1X EAP yêu cầu xác thực 2 chiều; máy trạm kiểm tra chứng chỉ số máy chủ trước khi gửi credentials. |
| **Lộ khóa chia sẻ RADIUS (Shared Secret)** | Thu thập gói tin giải mã shared secret yếu | Shared secret được đặt phức tạp, không lưu trong mã nguồn mở, nạp qua biến môi trường bảo mật `.env`. |
| **Tấn công Dashboard (SQLi, LDAPi)** | Chèn ký tự đặc biệt (`' OR '1'='1`) vào ô tìm kiếm | Toàn bộ truy vấn sử dụng **Prepared Statements** (tham số hóa); thư viện `ldap3` tự động escape các ký tự đặc biệt. |
| **Chiếm đoạt phiên quản trị (Session Hijacking)** | Đánh cắp session cookie của Quản trị viên | Thiết lập cờ `HttpOnly`, `SameSite=Lax`, tự động hủy phiên (Session Timeout) sau 30 phút rảnh rỗi; cách ly đa phiên Tab bằng Tab Session ID (`sid`). |
| **Lạm quyền quản trị (Admin Privilege Abuse)** | Quản trị viên cố tình xóa log hoặc sửa điểm | Cơ chế **RBAC** phân tách quyền Admin và Auditor; bảng `audit_logs` chỉ cho phép ghi (Append-Only), cấm xóa sửa. |
| **Nghe lén kết nối nội bộ LDAP** | Bắt trộm lưu lượng giữa FreeRADIUS và OpenLDAP | Phân đoạn mạng container riêng biệt `nac-net`; cấu hình hỗ trợ mã hóa StartTLS trên cổng 389. |

---

## CHƯƠNG 6: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

### 6.1. Các kết quả đã đạt được
1. **Hoàn thiện đầy đủ mô hình AAA**: Xây dựng thành công hệ thống tích hợp mượt mà giữa OpenLDAP, FreeRADIUS, MariaDB và Flask Web.
2. **Dynamic VLAN chuẩn hóa**: Chứng minh cơ chế gán VLAN động đạt 100% độ chính xác theo vai trò sinh viên, giảng viên, quản trị và cách ly.
3. **Phòng vệ chủ động thành công**: Kiểm thử và demo thành công chuỗi sự kiện "Tấn công brute-force $\to$ Tự động cách ly vào VLAN 99 $\to$ Ghi nhận Audit Log $\to$ Cảnh báo trực quan trên Dashboard".
4. **Tích hợp thành công Xác thực Đa nhân tố (MFA TOTP RFC 6238)**: Nâng tầm an ninh cho tài khoản quản trị mạng, quét mã QR qua Google/Microsoft Authenticator.
5. **Mở rộng Hệ thống Single Sign-On (SSO / OIDC)**: Cung cấp Cổng SSO Launchpad 1-chạm kết nối 5 ứng dụng nội bộ PTIT với Token JWT ký số chuẩn quốc tế.
6. **Tự động hóa hoàn toàn**: Triển khai toàn bộ hệ thống bằng một câu lệnh `docker compose up -d` với đầy đủ bộ công cụ kiểm thử tự động.

### 6.2. Hạn chế
- Hệ thống kiểm thử trong môi trường container ảo hóa, chưa thử nghiệm trực tiếp trên dòng Switch quản lý vật lý (Cisco Catalyst, Juniper).
- Chưa tích hợp cơ chế cấp phát chứng chỉ số PKI cho xác thực EAP-TLS hoàn chỉnh.

### 6.3. Hướng phát triển mở rộng
1. **Mở rộng Khóa cứng bảo mật (FIDO2 / WebAuthn)**: Bổ sung hỗ trợ khóa USB vật lý YubiKey / Windows Hello cho xác thực không cần mật khẩu (Passwordless).
2. **Tích hợp giao thức TACACS+**: Phục vụ phân quyền lệnh chi tiết (Command Authorization) trên thiết bị định tuyến Router của nhà mạng viễn thông.
