# TÀI LIỆU THIẾT KẾ BƯỚC 2: CÂY THƯ MỤC DANH TÍNH LDAP (DIT)

> **Dự án**: Quản lý truy cập mạng và xác thực trung tâm (NAC & Centralized Authentication)  
> **Môn học**: An toàn mạng - PTITHCM  
> **Phiên bản**: 1.0 (Ngày 1 - Bước 2)  

---

## I. TỔNG QUAN VÀ NGUYÊN TẮC THIẾT KẾ DIT

Cây thư mục thông tin danh tính (**Directory Information Tree - DIT**) là kiến trúc dữ liệu cốt lõi đóng vai trò là "Nguồn sự thật duy nhất" (*Single Source of Truth*) cho toàn bộ hệ thống xác thực mạng và phân quyền.

### Các nguyên tắc thiết kế được áp dụng:
1. **Phân cấp logic rõ ràng (Organizational Separation)**: Tách bạch giữa người dùng cuối (`ou=users`), nhóm quyền mạng (`ou=groups`), tài khoản dịch vụ hệ thống (`ou=services`), và vùng dự phòng cấu hình chính sách (`ou=policies`).
2. **Nguyên tắc đặc quyền tối thiểu (Least Privilege)**: Tách biệt tài khoản quản trị tối cao của LDAP (`cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn`) với tài khoản dịch vụ dành cho FreeRADIUS (`cn=radius-svc,ou=services,...`). FreeRADIUS chỉ được cấp quyền đọc (Read-only) đối với dữ liệu người dùng để hạn chế tối đa rủi ro nếu máy chủ RADIUS bị tấn công.
3. **Chuẩn hóa quan hệ Nhóm - Thành viên**: Sử dụng `objectClass: groupOfNames` với thuộc tính `member` chứa Distinguished Name (DN) đầy đủ của người dùng, tương thích hoàn hảo với module LDAP của FreeRADIUS và module OpenLDAP `memberof overlay`.

---

## II. SƠ ĐỒ CÂY THƯ MỤC DIT (DIRECTORY INFORMATION TREE)

```text
dc=attt,dc=ptit,dc=edu,dc=vn (Base DN - Gốc thư mục)
│
├── ou=users (Chứa toàn bộ tài khoản người dùng)
│   ├── uid=admin01    (Quản trị viên mạng & Dashboard)
│   ├── uid=gv_nguyen  (Giảng viên - Nhóm giangvien → VLAN 30)
│   ├── uid=sv_an      (Sinh viên - Nhóm sinhvien → VLAN 20)
│   ├── uid=sv_binh    (Sinh viên - Nhóm sinhvien → VLAN 20)
│   └── uid=sv_test    (Tài khoản thử nghiệm brute-force → Nhóm quarantine → VLAN 99)
│
├── ou=groups (Chứa các nhóm đối tượng phân quyền mạng)
│   ├── cn=quantri     (VLAN 10 - Quản trị mạng)
│   ├── cn=giangvien   (VLAN 30 - Cán bộ giảng viên)
│   ├── cn=sinhvien    (VLAN 20 - Sinh viên học tập)
│   └── cn=quarantine  (VLAN 99 - Phân đoạn cách ly tài khoản vi phạm)
│
├── ou=services (Chứa tài khoản dịch vụ nội bộ hệ thống)
│   └── cn=radius-svc  (Tài khoản chỉ đọc dành riêng cho FreeRADIUS kết nối LDAP)
│
└── ou=policies (Nhánh mở rộng lưu trữ chính sách mạng tập trung)
    └── (Dự phòng cho chính sách mở rộng hoặc cấu hình động)
```

---

## III. ĐẶC TẢ SCHEMA VÀ OBJECTCLASS CHO TỪNG ĐỐI TƯỢNG

### 1. Đối tượng Người dùng (`ou=users`)
Mỗi tài khoản người dùng được định nghĩa theo chuẩn `inetOrgPerson` (RFC 2798) kế thừa từ `organizationalPerson` và `person`.

* **ObjectClasses**:
  * `top`
  * `person`
  * `organizationalPerson`
  * `inetOrgPerson`
* **Thuộc tính bắt buộc & tùy chọn**:
  * `uid`: Định danh duy nhất (Username) dùng để đăng nhập mạng và Web Dashboard (ví dụ: `sv_an`).
  * `cn` (*Common Name*): Họ và tên đầy đủ của người dùng (ví dụ: `Nguyễn Văn An`).
  * `sn` (*Surname*): Họ của người dùng (ví dụ: `Nguyễn`).
  * `mail`: Hòm thư điện tử (ví dụ: `sv_an@ptit.edu.vn`).
  * `userPassword`: Mật khẩu được băm an toàn dạng `{SSHA}`.
  * `description`: Ghi chú vai trò hoặc tình trạng của tài khoản.

### 2. Đối tượng Nhóm phân quyền (`ou=groups`)
Nhóm sử dụng chuẩn `groupOfNames` (RFC 2256).

* **ObjectClasses**:
  * `top`
  * `groupOfNames`
* **Thuộc tính**:
  * `cn`: Tên nhóm (`quantri`, `giangvien`, `sinhvien`, `quarantine`).
  * `member`: Danh sách các DN của người dùng thuộc nhóm (ví dụ: `uid=sv_an,ou=users,dc=attt,dc=ptit,dc=edu,dc=vn`).
  * `description`: Mô tả nhóm và VLAN ID tương ứng.

### 3. Đối tượng Tài khoản Dịch vụ (`ou=services`)
* **ObjectClasses**:
  * `top`
  * `organizationalRole`
  * `simpleSecurityObject`
* **Thuộc tính**:
  * `cn`: Tên định danh dịch vụ (`radius-svc`).
  * `userPassword`: Mật khẩu băm `{SSHA}` dùng cho FreeRADIUS Bind DN.
  * `description`: Tài khoản dịch vụ Bind LDAP cho FreeRADIUS.

---

## IV. BẢNG DANH SÁCH TÀI KHOẢN MẪU KHỞI TẠO

Toàn bộ các tài khoản mẫu ban đầu được cấp mật khẩu mặc định an toàn là `P@ssword123!` (đã được băm SSHA trong file LDIF) để phục vụ kiểm thử:

| STT | Username (`uid`) | Họ và tên (`cn`) | Nhóm mặc định | VLAN ID gán | Kịch bản kiểm thử |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `admin01` | Quản trị viên hệ thống | `quantri` | VLAN 10 | Đăng nhập Dashboard, quản trị mạng toàn quyền. |
| 2 | `gv_nguyen` | Thầy Nguyễn Văn Giảng | `giangvien` | VLAN 30 | Truy cập mạng nghiên cứu và cổng nhập điểm. |
| 3 | `sv_an` | Sinh viên Nguyễn Văn An | `sinhvien` | VLAN 20 | Truy cập Wi-Fi sinh viên và Internet thông thường. |
| 4 | `sv_binh` | Sinh viên Lê Thị Bình | `sinhvien` | VLAN 20 | Kiểm thử đăng nhập đồng thời nhiều tài khoản. |
| 5 | `sv_test` | Tài khoản Kiểm thử | `sinhvien` | VLAN 20 $\to$ 99 | Đối tượng dùng để tấn công brute-force thử nghiệm; sau khi sai quá 5 lần sẽ bị chuyển sang nhóm `quarantine` (VLAN 99). |
| 6 | `radius-svc` | FreeRADIUS Service | *Không có* | *N/A* | Tài khoản dịch vụ kết nối LDAP (Bind DN), chỉ đọc. |

---

## V. CƠ CHẾ BẢO MẬT & QUYỀN TRUY CẬP (ACCESS CONTROL - ACL)

Nhằm tuân thủ yêu cầu môn học An toàn mạng về **Phòng thủ theo chiều sâu (Defense-in-Depth)** và **Kiểm soát truy cập (Access Control)**, cấu hình Access Control List (ACL) trên OpenLDAP được thiết lập như sau:

1. **Mật khẩu (`userPassword`)**:
   - `radius-svc` và `admin` có quyền so khớp/xác thực (*auth/compare*).
   - Người dùng tự đổi được mật khẩu của chính mình (*write* by self).
   - Mọi đối tượng khác tuyệt đối không được đọc (*none* by others/anonymous).
2. **Cây dữ liệu người dùng (`ou=users`, `ou=groups`)**:
   - `radius-svc` chỉ có quyền đọc (*read*).
   - Dashboard Admin kết nối qua tài khoản Admin để có quyền ghi (*write*).
   - Anonymous (người dùng chưa xác thực) không được phép tìm kiếm dữ liệu (*disallow bind_anon*).
