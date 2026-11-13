-- ====================================================================
-- KHỞI TẠO CƠ SỞ DỮ LIỆU CHÍNH SÁCH MẠNG & FREERADIUS AUTHORIZATION
-- Đề tài: Quản lý truy cập mạng và xác thực trung tâm (NAC)
-- ====================================================================

-- 1. BẢNG radacct (ACCOUNTING / GHI NHẬN LƯU LƯỢNG VÀ PHIÊN)
CREATE TABLE IF NOT EXISTS radacct (
  radacctid bigint(21) NOT NULL auto_increment,
  acctsessionid varchar(64) NOT NULL default '',
  acctuniqueid varchar(32) NOT NULL default '',
  username varchar(64) NOT NULL default '',
  realm varchar(64) default '',
  nasipaddress varchar(15) NOT NULL default '',
  nasportid varchar(32) default NULL,
  nasporttype varchar(32) default NULL,
  acctstarttime datetime NULL default NULL,
  acctupdatetime datetime NULL default NULL,
  acctstoptime datetime NULL default NULL,
  acctinterval int(12) default NULL,
  acctsessiontime int(12) unsigned default NULL,
  acctauthentic varchar(32) default NULL,
  connectinfo_start varchar(128) default NULL,
  connectinfo_stop varchar(128) default NULL,
  acctinputoctets bigint(20) default NULL,
  acctoutputoctets bigint(20) default NULL,
  calledstationid varchar(50) NOT NULL default '',
  callingstationid varchar(50) NOT NULL default '',
  acctterminatecause varchar(32) NOT NULL default '',
  servicetype varchar(32) default NULL,
  framedprotocol varchar(32) default NULL,
  framedipaddress varchar(15) NOT NULL default '',
  framedipv6address varchar(45) NOT NULL default '',
  framedipv6prefix varchar(45) NOT NULL default '',
  framedinterfaceid varchar(44) NOT NULL default '',
  delegatedipv6prefix varchar(45) NOT NULL default '',
  class varchar(64) default NULL,
  PRIMARY KEY (radacctid),
  UNIQUE KEY acctuniqueid (acctuniqueid),
  KEY username (username),
  KEY framedipaddress (framedipaddress),
  KEY acctsessionid (acctsessionid),
  KEY acctstarttime (acctstarttime),
  KEY acctstoptime (acctstoptime)
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 2. BẢNG radcheck
CREATE TABLE IF NOT EXISTS radcheck (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY (id),
  KEY username (username(32))
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 3. BẢNG radgroupcheck
CREATE TABLE IF NOT EXISTS radgroupcheck (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY (id),
  KEY groupname (groupname(32))
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 4. BẢNG radgroupreply (TRẢ VỀ CÁC THUỘC TÍNH DYNAMIC VLAN CHO FREERADIUS)
CREATE TABLE IF NOT EXISTS radgroupreply (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY (id),
  KEY groupname (groupname(32))
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 5. BẢNG radreply
CREATE TABLE IF NOT EXISTS radreply (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY (id),
  KEY username (username(32))
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 6. BẢNG radusergroup
CREATE TABLE IF NOT EXISTS radusergroup (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  groupname varchar(64) NOT NULL default '',
  priority int(11) NOT NULL default '1',
  PRIMARY KEY (id),
  KEY username (username(32))
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 7. BẢNG radpostauth (LƯU NHẬT KÝ XÁC THỰC - ACCOUNTING / LOGGING)
CREATE TABLE IF NOT EXISTS radpostauth (
  id int(11) NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  pass varchar(64) NOT NULL default '',
  reply varchar(32) NOT NULL default '',
  authdate timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  class varchar(64) default NULL,
  PRIMARY KEY (id),
  KEY username (username),
  KEY authdate (authdate)
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 8. BẢNG nas (DANH SÁCH THIẾT BỊ MẠNG / ACCESS POINT / CLIENT)
CREATE TABLE IF NOT EXISTS nas (
  id int(10) NOT NULL auto_increment,
  nasname varchar(128) NOT NULL,
  shortname varchar(32),
  type varchar(30) DEFAULT 'other',
  ports int(5),
  secret varchar(60) DEFAULT 'secret' NOT NULL,
  server varchar(64),
  community varchar(50),
  description varchar(200) DEFAULT 'RADIUS Client',
  PRIMARY KEY (id),
  KEY nasname (nasname)
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- 9. BẢNG policy_matrix (DÀNH CHO WEB DASHBOARD QUẢN TRỊ VIÊN)
CREATE TABLE IF NOT EXISTS policy_matrix (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(64) NOT NULL UNIQUE COMMENT 'Tên nhóm tương ứng trên OpenLDAP',
    vlan_id INT NOT NULL COMMENT 'Mã VLAN gán động (Dynamic VLAN ID)',
    vlan_name VARCHAR(64) NOT NULL COMMENT 'Tên phân đoạn mạng',
    subnet_cidr VARCHAR(32) NOT NULL COMMENT 'Dải địa chỉ IP giả định',
    session_timeout INT DEFAULT 14400 COMMENT 'Thời lượng tối đa của một phiên (giây)',
    idle_timeout INT DEFAULT 600 COMMENT 'Thời gian rảnh trước khi ngắt phiên (giây)',
    priority INT DEFAULT 10 COMMENT 'Trọng số ưu tiên khi giải quyết xung đột nhóm',
    description TEXT COMMENT 'Mô tả mục đích và phạm vi tài nguyên truy cập',
    is_active TINYINT(1) DEFAULT 1 COMMENT '1 = Kích hoạt, 0 = Tạm dừng',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. BẢNG audit_logs (LƯU VẾT THAO TÁC CỦA ADMIN THEO USER STORY US08)
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    actor_username VARCHAR(64) NOT NULL COMMENT 'Admin thực hiện hành động',
    action VARCHAR(64) NOT NULL COMMENT 'Tên hành động (CREATE_USER, CHANGE_VLAN, UNLOCK, etc.)',
    target VARCHAR(128) NOT NULL COMMENT 'Đối tượng bị tác động (username hoặc group)',
    old_value TEXT DEFAULT NULL COMMENT 'Giá trị cũ trước khi sửa',
    new_value TEXT DEFAULT NULL COMMENT 'Giá trị mới sau khi sửa',
    ip_address VARCHAR(45) NOT NULL COMMENT 'IP của người thực hiện',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ====================================================================
-- DỮ LIỆU KHỞI TẠO BAN ĐẦU (SEED DATA)
-- ====================================================================

-- Cấu hình NAS Client cho phép mọi địa chỉ trong mạng Docker truy cập với shared secret: testing123
INSERT INTO nas (nasname, shortname, type, secret, description)
VALUES ('0.0.0.0/0', 'docker-all', 'other', 'testing123', 'Allow all docker containers')
ON DUPLICATE KEY UPDATE secret = 'testing123';

-- Nạp ma trận chính sách mạng
INSERT INTO policy_matrix 
(group_name, vlan_id, vlan_name, subnet_cidr, session_timeout, idle_timeout, priority, description)
VALUES 
('quarantine', 99, 'VLAN Cách ly', '10.10.99.0/24', 1800, 300, 1000, 'Phân đoạn cách ly tài khoản vi phạm hoặc nghi ngờ dò mật khẩu brute-force'),
('quantri',    10, 'VLAN Quản trị', '10.10.10.0/24', 7200, 900, 100,  'Phân đoạn quản trị mạng nội bộ, máy chủ và hạ tầng'),
('giangvien',  30, 'VLAN Giảng viên', '10.10.30.0/24', 28800, 1800, 50,  'Phân đoạn dành cho cán bộ giảng viên truy cập hệ thống nghiệp vụ và LMS'),
('sinhvien',   20, 'VLAN Sinh viên', '10.10.20.0/24', 14400, 600, 10,  'Phân đoạn học tập cho sinh viên, truy cập Internet và Cổng thông tin đào tạo')
ON DUPLICATE KEY UPDATE 
    vlan_id = VALUES(vlan_id),
    vlan_name = VALUES(vlan_name),
    subnet_cidr = VALUES(subnet_cidr),
    session_timeout = VALUES(session_timeout),
    idle_timeout = VALUES(idle_timeout),
    priority = VALUES(priority),
    description = VALUES(description);

-- Nạp thuộc tính Dynamic VLAN vào bảng radgroupreply
DELETE FROM radgroupreply WHERE groupname IN ('quantri', 'giangvien', 'sinhvien', 'quarantine');

-- Nhóm 1: quantri (VLAN 10)
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('quantri', 'Tunnel-Type', ':=', 'VLAN'),
('quantri', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
('quantri', 'Tunnel-Private-Group-Id', ':=', '10'),
('quantri', 'Session-Timeout', ':=', '7200'),
('quantri', 'Idle-Timeout', ':=', '900'),
('quantri', 'Termination-Action', ':=', '1');

-- Nhóm 2: giangvien (VLAN 30)
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('giangvien', 'Tunnel-Type', ':=', 'VLAN'),
('giangvien', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
('giangvien', 'Tunnel-Private-Group-Id', ':=', '30'),
('giangvien', 'Session-Timeout', ':=', '28800'),
('giangvien', 'Idle-Timeout', ':=', '1800'),
('giangvien', 'Termination-Action', ':=', '1');

-- Nhóm 3: sinhvien (VLAN 20)
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('sinhvien', 'Tunnel-Type', ':=', 'VLAN'),
('sinhvien', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
('sinhvien', 'Tunnel-Private-Group-Id', ':=', '20'),
('sinhvien', 'Session-Timeout', ':=', '14400'),
('sinhvien', 'Idle-Timeout', ':=', '600'),
('sinhvien', 'Termination-Action', ':=', '1');

-- Nhóm 4: quarantine (VLAN 99)
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('quarantine', 'Tunnel-Type', ':=', 'VLAN'),
('quarantine', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
('quarantine', 'Tunnel-Private-Group-Id', ':=', '99'),
('quarantine', 'Session-Timeout', ':=', '1800'),
('quarantine', 'Idle-Timeout', ':=', '300'),
('quarantine', 'Termination-Action', ':=', '1');

-- Ghi nhận sự kiện khởi tạo hệ thống
INSERT INTO audit_logs (actor_username, action, target, new_value, ip_address)
VALUES ('SYSTEM_INIT', 'INIT_DATABASE', 'SCHEMA_AND_POLICIES', 'Khoi tao thanh cong 4 nhom VLAN mac dinh', '127.0.0.1');

-- ====================================================================
-- 7. BẢNG user_mfa (XÁC THỰC ĐA NHÂN TỐ TOTP RFC 6238)
-- ====================================================================
CREATE TABLE IF NOT EXISTS user_mfa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    secret_key VARCHAR(64) NOT NULL,
    is_enabled TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used_at DATETIME NULL
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

-- ====================================================================
-- 8. BẢNG sso_clients & sso_auth_codes (SINGLE SIGN-ON & OIDC)
-- ====================================================================
CREATE TABLE IF NOT EXISTS sso_clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL UNIQUE,
    client_name VARCHAR(128) NOT NULL,
    client_secret VARCHAR(128) NOT NULL,
    redirect_uri VARCHAR(255) NOT NULL,
    description VARCHAR(255) DEFAULT '',
    icon_class VARCHAR(64) DEFAULT 'fa-solid fa-cube',
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS sso_auth_codes (
    code VARCHAR(64) PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    username VARCHAR(64) NOT NULL,
    redirect_uri VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL
) ENGINE = INNODB DEFAULT CHARSET=utf8mb4;

INSERT INTO sso_clients (client_id, client_name, client_secret, redirect_uri, description, icon_class)
VALUES 
('qldt_lms', 'Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)', 'sec_qldt_9921', 'http://qldt.ptit.edu.vn/sso/callback', 'Hệ thống quản lý điểm thi, thời khóa biểu và lớp học trực tuyến LMS', 'fa-solid fa-graduation-cap'),
('elibrary', 'Thư viện Số & Học liệu PTIT (E-Library)', 'sec_lib_8832', 'http://lib.ptit.edu.vn/sso/callback', 'Cổng tra cứu tài liệu học tập, giáo trình chuyên ngành ATTT', 'fa-solid fa-book-bookmark'),
('vpn_portal', 'Cổng Truy cập Từ xa (Zero-Trust VPN Gateway)', 'sec_vpn_7743', 'http://vpn.ptit.edu.vn/sso/callback', 'Cổng kết nối bảo mật VPN IPSec/SSL dành cho giảng viên và quản trị viên', 'fa-solid fa-shield-halved'),
('webmail', 'Hệ thống Thư điện tử Sinh viên & Cán bộ (Webmail)', 'sec_mail_6654', 'http://mail.ptit.edu.vn/sso/callback', 'Dịch vụ Email cộng tác nội bộ trường @ptit.edu.vn', 'fa-solid fa-envelope'),
('nac_admin', 'Bảng điều khiển Quản trị mạng Trung tâm (NAC Console)', 'sec_nac_5565', 'http://localhost:5000/sso/callback', 'Trung tâm điều khiển NAC, RADIUS AAA và OpenLDAP', 'fa-solid fa-network-wired')
ON DUPLICATE KEY UPDATE client_name=VALUES(client_name);
