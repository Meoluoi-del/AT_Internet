# Đồ án An toàn mạng: Quản lý truy cập mạng và xác thực trung tâm

*Tổng hợp mục tiêu, mục đích và kế hoạch thực hiện trong 8 ngày*

## 1. Bài toán và mục tiêu tổng thể

**Vấn đề thực tế**: một tổ chức có hàng trăm người dùng và thiết bị (Wi-Fi, VPN, switch, server). Nếu mỗi thiết bị tự giữ danh sách tài khoản riêng thì sẽ gặp các vấn đề sau:

- Nhân viên nghỉ việc nhưng tài khoản vẫn còn ở vài nơi.
- Đổi mật khẩu hoặc phân quyền phải làm thủ công ở nhiều chỗ.
- Không ai biết ai đã vào mạng lúc nào.

**Giải pháp đồ án chứng minh**: gom về một nơi duy nhất.

- Một **thư mục danh tính** (LDAP) để lưu ai là ai.
- Một **máy chủ AAA** (RADIUS) để quyết định ai được vào mạng, vào với quyền gì, và ghi lại họ đã làm gì.
- Một **công cụ quản trị** (do bạn xây) để quản lý những thứ trên bằng giao diện thay vì gõ lệnh.

**Mục tiêu của bạn**

1. Hiểu và trình bày được cơ chế AAA, NAC, 802.1X/RADIUS, LDAP.
2. Dựng được hệ thống chạy thật, có bằng chứng bằng log và ảnh chụp.
3. Xây được công cụ quản lý có giá trị thực tế (phần sáng tạo của bạn).
4. Phân tích được rủi ro và tấn công vào chính hệ thống, rồi chứng minh biện pháp phòng thủ. Đây là điều môn An toàn mạng muốn thấy.

## 2. Các khái niệm cần nắm (và vì sao)

| Khái niệm | Là gì | Vai trò trong đồ án |
| --- | --- | --- |
| **AAA** | Authentication (bạn là ai), Authorization (bạn được làm gì), Accounting (bạn đã làm gì) | Khung lý thuyết xương sống của cả báo cáo |
| **NAC** | Kiểm soát thiết bị/người dùng trước khi cho vào mạng | Tên đề tài, là mục đích của cả hệ thống |
| **802.1X / EAP** | Chuẩn xác thực ở cổng mạng (Wi-Fi/switch) | Cách người dùng "gõ cửa" mạng |
| **RADIUS** | Giao thức giữa thiết bị mạng và máy chủ AAA | Bộ não ra quyết định |
| **LDAP** | Giao thức truy vấn thư mục người dùng | Kho danh tính tập trung (phần "xác thực trung tâm") |
| **SSO / Kerberos** | Đăng nhập một lần cho nhiều dịch vụ | Chỉ cần giải thích và so sánh ở phần lý thuyết |

## 3. Sản phẩm cuối cùng cần có

- Hệ thống lab chạy bằng `docker-compose` (OpenLDAP, FreeRADIUS, CSDL, Flask)
- Công cụ quản lý (dashboard) với đầy đủ chức năng MVP
- Báo cáo hoàn chỉnh
- Slide thuyết trình
- Video demo ngắn (dự phòng khi demo trực tiếp bị lỗi)
- Mã nguồn và hướng dẫn chạy (README)

## 4. Vai trò từng thành phần

| Thành phần | Vai trò | Vì sao phải có |
| --- | --- | --- |
| **OpenLDAP** | Lưu user, nhóm, mật khẩu (dạng băm) | Là "nguồn sự thật" duy nhất về danh tính |
| **FreeRADIUS** | Nhận yêu cầu, hỏi LDAP, trả Accept/Reject kèm thuộc tính (VLAN) | Thực hiện Authentication và Authorization |
| **CSDL SQL** | Lưu chính sách, log xác thực, phiên truy cập | Thực hiện Accounting, và dashboard có dữ liệu để hiển thị |
| **Flask dashboard** | Giao diện quản trị: user, nhóm, chính sách, giám sát | Phần sáng tạo của bạn |
| **`radtest` / `eapol_test`** | Giả lập thiết bị người dùng | Không có switch/AP thật, nên cần công cụ đóng vai máy khách |

Có một giới hạn nên nói thẳng trong báo cáo: lab không có switch thật nên "gán VLAN" được chứng minh bằng việc RADIUS **trả đúng thuộc tính VLAN** trong gói Accept. Việc thiết bị thật áp dụng thuộc tính đó nằm ngoài phạm vi.

## 5. Công việc chi tiết theo ngày

### Ngày 1: Phạm vi và thiết kế

- **Mục tiêu**: biết chính xác mình sẽ làm gì và không làm gì.
- **Việc cần làm**:
  - Viết 8–10 user story, ví dụ "Admin tạo user và gán nhóm", "Auditor xem log nhưng không sửa được".
  - Thiết kế cây LDAP với nhóm `sinhvien`, `giangvien`, `quantri`, `quarantine`.
  - Thiết kế bảng chính sách, ví dụ sinhvien → VLAN 20, giangvien → VLAN 30, quarantine → VLAN 99.
  - Vẽ sơ đồ kiến trúc và luồng xác thực: người dùng → thiết bị mạng → RADIUS → LDAP → Accept kèm VLAN.
- **Mục đích**: phần lớn sai sót ở đồ án đến từ việc vừa làm vừa nghĩ. Thiết kế xong trước thì 7 ngày sau chỉ còn lắp ráp.
- **Hoàn thành khi**: có sơ đồ, schema và danh sách user story đã chốt.

### Ngày 2: Lý thuyết và khung hạ tầng

- **Mục tiêu**: hiểu đủ để giải thích, và có khung chạy sẵn.
- **Việc cần làm**: đọc và viết nháp Chương 1–2 của báo cáo (AAA, NAC, 802.1X/EAP, RADIUS vs TACACS+, LDAP, Kerberos/SSO). Song song, dựng khung `docker-compose` với các container.
- **Mục đích**: Chương 4 của môn chưa dạy các giao thức này, nên đây là phần bạn phải tự chứng minh mình hiểu. Dựng khung sớm để ngày 3–4 không mất thời gian xử lý lỗi môi trường.
- **Hoàn thành khi**: `docker compose up` chạy được các container và có bản nháp lý thuyết.

### Ngày 3: Xác thực qua LDAP

- **Mục tiêu**: user trong LDAP đăng nhập được qua RADIUS.
- **Việc cần làm**: nạp user và nhóm mẫu vào LDAP, cấu hình FreeRADIUS gọi LDAP, kiểm tra bằng `radtest` với cả mật khẩu đúng và sai.
- **Mục đích**: đây là lõi của "xác thực trung tâm". Từ đây trở đi mọi thứ khác chỉ là mở rộng.
- **Hoàn thành khi**: có log Access-Accept và Access-Reject đúng kỳ vọng.

### Ngày 4: Chính sách, accounting và EAP

- **Mục tiêu**: có phân quyền và ghi nhận.
- **Việc cần làm**: nối FreeRADIUS với SQL để trả thuộc tính VLAN theo nhóm và ghi `radacct`, `radpostauth`. Thử PEAP-MSCHAPv2 bằng `eapol_test`.
- **Mục đích**: hoàn thiện đủ ba chữ A. PEAP là cách xác thực mà Wi-Fi doanh nghiệp thật sự dùng. Ngày này dễ vướng nhất vì chứng chỉ và EAP, nên có phương án dự phòng là PAP.
- **Hoàn thành khi**: Accept trả đúng VLAN theo nhóm, và dữ liệu xuất hiện trong SQL.

### Ngày 5: Dashboard, backend

- **Mục tiêu**: quản lý bằng giao diện thay vì dòng lệnh.
- **Việc cần làm**: đăng nhập dashboard với phân vai admin/auditor, thêm/sửa/xóa user và nhóm trên LDAP, quản lý chính sách nhóm → VLAN. Bạn đã có sẵn module băm mật khẩu và logic khóa tài khoản sau nhiều lần sai từ dự án xác thực Flask, nên tái sử dụng cho phần đăng nhập admin sẽ tiết kiệm nhiều thời gian. Lưu ý đây chỉ dùng cho tài khoản admin của dashboard, còn mật khẩu người dùng cuối do LDAP tự băm và lưu.
- **Mục đích**: đây là "công cụ quản lý truy cập mạng" của đề tài. Nó biến một cụm dịch vụ rời rạc thành một sản phẩm.
- **Hoàn thành khi**: thao tác tạo user trên web, rồi `radtest` đăng nhập bằng user đó thành công.

### Ngày 6: Giám sát và phát hiện

- **Mục tiêu**: hệ thống không chỉ cho phép mà còn quan sát được.
- **Việc cần làm**:
  - Hiển thị phiên đang hoạt động và log xác thực.
  - Phát hiện brute-force: sai N lần trong M phút thì chuyển user vào nhóm `quarantine`.
  - Ghi audit log cho mọi thao tác của admin.
- **Mục đích**: ứng với "Detection" trong mô hình bảo mật 3D và "Accountability" trong mô hình 5 thuộc tính của Chương 1. Đây là phần nối đồ án với nội dung môn học.
- **Hoàn thành khi**: demo được chuỗi "đoán sai mật khẩu nhiều lần → bị cách ly → thấy trên dashboard".

### Ngày 7: Đánh giá bảo mật, báo cáo, demo

- **Mục tiêu**: biến sản phẩm thành bài nộp.
- **Việc cần làm**: viết chương đánh giá bảo mật (mục 6), hoàn thiện báo cáo, quay video demo, làm slide.
- **Mục đích**: giảng viên chấm báo cáo và phần phân tích nhiều hơn chấm code.
- **Hoàn thành khi**: có báo cáo, slide và video bản đầy đủ.

### Ngày 8: Dự phòng

Rà soát lỗi chính tả và số liệu, tập thuyết trình, chuẩn bị câu hỏi phản biện (ví dụ "vì sao không tự viết RADIUS?", "LDAP khác AD thế nào?"), kiểm tra lần cuối rằng hệ thống chạy từ đầu trên máy sạch.

## 6. Nội dung báo cáo và mục đích từng chương

| Chương | Nội dung | Mục đích |
| --- | --- | --- |
| 1. Tổng quan | Bài toán, mục tiêu, phạm vi và giới hạn | Cho người đọc biết bạn giải quyết vấn đề gì |
| 2. Cơ sở lý thuyết | AAA, NAC, 802.1X/EAP, RADIUS, LDAP, SSO, DAC/MAC/RBAC | Chứng minh hiểu biết |
| 3. Phân tích và thiết kế | Quy trình 5 bước (tài sản → rủi ro → bảo vệ → công cụ → ưu tiên), tính ALE = SLE × ARO với số liệu giả định ghi rõ, sơ đồ và schema | Cho thấy bạn thiết kế có cơ sở, không làm tùy hứng |
| 4. Triển khai | Cấu hình, đoạn mã chính, ảnh chụp, kết quả test | Bằng chứng hệ thống chạy thật |
| 5. Đánh giá bảo mật | Bảng mối đe dọa và biện pháp (bên dưới) | Phần thể hiện đúng tinh thần môn học |
| 6. Kết luận | Kết quả, hạn chế, hướng phát triển (TACACS+, MFA, SSO) | Đóng bài một cách trung thực |

**Bảng mối đe dọa cho Chương 5**

| Mối đe dọa | Biện pháp |
| --- | --- |
| Dò mật khẩu (brute-force) | Phát hiện và cách ly tự động, khóa tài khoản |
| Nghe lén mật khẩu | Dùng EAP trong đường hầm TLS thay vì PAP thuần |
| Thiết bị phát Wi-Fi giả (rogue AP) | Máy khách kiểm tra chứng chỉ của máy chủ |
| Lộ shared secret RADIUS | Secret dài, ngẫu nhiên, không lưu trong mã nguồn |
| SQL injection / LDAP injection vào dashboard | Truy vấn tham số hóa, escape đầu vào LDAP |
| CSRF, chiếm session | Token CSRF, cookie an toàn, hết hạn session |
| Admin lạm quyền | RBAC, audit log, tài khoản auditor chỉ đọc |
| Nghe lén kết nối tới LDAP | Dùng LDAPS/StartTLS |

## 7. Kịch bản demo (3–5 phút)

1. Admin đăng nhập dashboard, tạo user mới và gán vào nhóm `sinhvien`.
2. Chạy `radtest` với user đó thì được Accept kèm VLAN 20.
3. Đổi nhóm sang `giangvien` thì lần sau nhận VLAN 30.
4. Đoán sai mật khẩu vài lần thì user bị đưa vào `quarantine` (VLAN 99), dashboard hiện cảnh báo.
5. Mở audit log và log xác thực để chứng minh khả năng truy vết.

## 8. Liên hệ với môn học

Để báo cáo "đúng chất" An toàn mạng:

- **Chương 1**: tính xác thực và tính truy vết (Authenticity, Accountability), mô hình 3D (phòng thủ, răn đe, phát hiện), phòng thủ theo chiều sâu (onion), phân tích rủi ro, vai trò đội ứng phó sự cố.
- **Chương 4**: các mô hình kiểm soát truy cập (DAC, MAC, RBAC), xác thực đa nhân tố, VPN/IPsec.
- **Không có "viên đạn bạc"**: nhấn mạnh rằng NAC chỉ là một lớp, cần đi cùng tường lửa, giám sát và đào tạo người dùng.

## 9. Rủi ro và ngưỡng cắt giảm

| Nếu... | Thì... |
| --- | --- |
| Ngày 4 chưa chạy được PEAP | Dùng PAP/CHAP để có demo, ghi PEAP là hướng phát triển |
| Cuối ngày 5 chưa xong backend | Bỏ brute-force tự động, giữ MVP |
| Thiếu thời gian báo cáo | Giữ nguyên Chương 5, rút gọn Chương 2 |

**Nguyên tắc**: luôn có một bản chạy được ở cuối mỗi ngày, và không bao giờ cắt phần đánh giá bảo mật.
