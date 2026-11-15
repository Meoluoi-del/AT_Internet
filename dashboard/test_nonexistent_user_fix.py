import unittest
import requests
from models import DBManager, get_db_connection
from detector import detector_instance
from ldap_client import LDAPClient

class TestNonExistentUserAlertFix(unittest.TestCase):
    def setUp(self):
        self.lc = LDAPClient()
        self.conn = get_db_connection()

    def tearDown(self):
        self.conn.close()

    def test_01_user_exists_method(self):
        """Kiểm tra phương thức user_exists hoạt động chuẩn xác với OpenLDAP"""
        self.assertTrue(self.lc.user_exists('sv_an'))
        self.assertFalse(self.lc.user_exists('sv_vinh'))
        self.assertFalse(self.lc.user_exists('ghost_attacker_xyz'))
        print("OK: user_exists xac thuc dung danh tinh trong OpenLDAP!")

    def test_02_detector_ignores_non_existent_user(self):
        """Kiểm tra get_live_attacks và _check_bruteforce_attempts bỏ qua user không tồn tại"""
        # Thêm 6 Access-Reject cho tài khoản ma ghost_user_999
        with self.conn.cursor() as cursor:
            for _ in range(6):
                cursor.execute(
                    "INSERT INTO radpostauth (username, pass, reply) VALUES (%s, %s, %s)",
                    ('ghost_user_999', '123456', 'Access-Reject')
                )

        # 1. get_live_attacks() không được chứa ghost_user_999
        attacks = detector_instance.get_live_attacks()
        ghost_found = any(a['username'] == 'ghost_user_999' for a in attacks)
        self.assertFalse(ghost_found, "ghost_user_999 khong duoc phep xuat hien trong live attacks!")
        print("OK: get_live_attacks() da loc bo hoan toan user khong ton tai!")

        # 2. _check_bruteforce_attempts() không được đưa ghost_user_999 vào recent_alerts
        detector_instance._check_bruteforce_attempts()
        alert_found = any(a['username'] == 'ghost_user_999' for a in detector_instance.recent_alerts)
        self.assertFalse(alert_found, "ghost_user_999 khong duoc phep sinh alert!")
        print("OK: _check_bruteforce_attempts() khong sinh alert cho user khong ton tai!")

    def test_03_dashboard_login_non_existent_user(self):
        """Kiểm tra trang đăng nhập Dashboard không sinh cảnh báo đếm khóa tài khoản cho user không tồn tại"""
        s = requests.Session()
        r = s.get('http://127.0.0.1:5000/login')
        sid = r.url.split('sid=')[-1]
        
        # Thử đăng nhập bằng tài khoản không có trong ADMIN_USERS
        resp = s.post('http://127.0.0.1:5000/login', data={
            'username': 'ghost_admin_fake',
            'password': 'wrongpassword123',
            'sid': sid
        })
        self.assertIn('Sai tên đăng nhập hoặc mật khẩu!', resp.text)
        self.assertNotIn('lần thử trước khi tài khoản bị khóa', resp.text)
        print("OK: Dang nhap user khong ton tai khong sinh canh bao dem nguoc khoa tai khoan!")

        # Kiểm tra bảng dashboard_account_lockouts không có dòng nào cho ghost_admin_fake
        with self.conn.cursor() as cursor:
            cursor.execute("SELECT * FROM dashboard_account_lockouts WHERE username = %s", ('ghost_admin_fake',))
            row = cursor.fetchone()
            self.assertIsNone(row, "dashboard_account_lockouts khong duoc phep ghi nhan user ao!")
        print("OK: dashboard_account_lockouts khong bi chen tai khoan khong ton tai!")

    def test_04_dashboard_login_real_user(self):
        """Kiểm tra trang đăng nhập Dashboard vẫn cảnh báo đếm ngược khóa tài khoản cho user thật (admin)"""
        s = requests.Session()
        r = s.get('http://127.0.0.1:5000/login')
        sid = r.url.split('sid=')[-1]
        
        resp = s.post('http://127.0.0.1:5000/login', data={
            'username': 'admin',
            'password': 'WrongAdminPassword123!',
            'sid': sid
        })
        self.assertIn('lần thử trước khi tài khoản bị khóa', resp.text)
        print("OK: Dang nhap user that (admin) van canh bao so lan thu con lai dung quy tac!")

        # Reset số lần sai của admin để không ảnh hưởng
        DBManager.record_dashboard_login_success('admin', '127.0.0.1')

if __name__ == '__main__':
    unittest.main()
