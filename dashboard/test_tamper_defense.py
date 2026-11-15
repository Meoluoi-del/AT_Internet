import unittest
import time
import pymysql
from models import DBManager, get_db_connection
from detector import detector_instance
from ldap_client import LDAPClient
from config import Config

class TestForensicIntegrityAndActiveDefense(unittest.TestCase):
    def setUp(self):
        self.conn = get_db_connection()
        self.ldap_client = LDAPClient()

    def tearDown(self):
        self.conn.close()

    def test_01_audit_logs_append_only_trigger(self):
        """Kiểm tra Trigger chặn UPDATE và DELETE trên audit_logs (SQLSTATE 45000)"""
        with self.conn.cursor() as cursor:
            # 1. UPDATE phải bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("UPDATE audit_logs SET action = 'MALICIOUS_MOD' WHERE id = 1")
            self.assertIn("audit_logs is strictly append-only", str(ctx.exception))
            print("OK: UPDATE audit_logs bi chan dung boi trigger SQLSTATE 45000")

            # 2. DELETE phải bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("DELETE FROM audit_logs WHERE id = 1")
            self.assertIn("audit_logs is strictly append-only", str(ctx.exception))
            print("OK: DELETE audit_logs bi chan dung boi trigger SQLSTATE 45000")

    def test_02_radpostauth_append_only_trigger(self):
        """Kiểm tra Trigger chặn UPDATE và DELETE trên radpostauth (Bảo vệ bằng chứng số)"""
        with self.conn.cursor() as cursor:
            # Insert một bản ghi mẫu
            cursor.execute("""
                INSERT INTO radpostauth (username, pass, reply)
                VALUES ('forensic_test_user', 'wrong_pass', 'Access-Reject')
            """)
            cursor.execute("SELECT LAST_INSERT_ID() as lid")
            row_id = cursor.fetchone()['lid']

            # 1. UPDATE phải bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("""
                    UPDATE radpostauth 
                    SET reply = 'Access-Reject-Resolved' 
                    WHERE id = %s
                """, (row_id,))
            self.assertIn("radpostauth is strictly append-only", str(ctx.exception))
            print("OK: UPDATE radpostauth bi chan dung boi trigger SQLSTATE 45000")

            # 2. DELETE phải bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("DELETE FROM radpostauth WHERE id = %s", (row_id,))
            self.assertIn("radpostauth is strictly append-only", str(ctx.exception))
            print("OK: DELETE radpostauth bi chan dung boi trigger SQLSTATE 45000")

    def test_03_quarantine_events_append_only_trigger(self):
        """Kiểm tra Trigger chặn UPDATE và DELETE trên quarantine_events"""
        with self.conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO quarantine_events (username, event_type, reason, failed_count, source)
                VALUES ('forensic_test_user', 'QUARANTINE', 'Testing triggers', 6, 'TEST_SUITE')
            """)
            cursor.execute("SELECT LAST_INSERT_ID() as lid")
            row_id = cursor.fetchone()['lid']

            # 1. UPDATE bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("UPDATE quarantine_events SET reason = 'MODIFIED' WHERE id = %s", (row_id,))
            self.assertIn("quarantine_events is strictly append-only", str(ctx.exception))
            print("OK: UPDATE quarantine_events bi chan dung boi trigger SQLSTATE 45000")

            # 2. DELETE bị chặn
            with self.assertRaises(pymysql.err.OperationalError) as ctx:
                cursor.execute("DELETE FROM quarantine_events WHERE id = %s", (row_id,))
            self.assertIn("quarantine_events is strictly append-only", str(ctx.exception))
            print("OK: DELETE quarantine_events bi chan dung boi trigger SQLSTATE 45000")

    def test_04_cryptographic_hash_chain_verification(self):
        """Kiểm tra tính liên tục và xác thực của chuỗi Hash-Chain trong audit_logs"""
        # Thêm 2 bản ghi audit mới
        DBManager.add_audit_log(
            actor="admin_tester",
            action="TEST_ACTION_CHAIN_1",
            target="SYSTEM",
            new_value="Test payload 1",
            ip="192.168.1.100"
        )
        DBManager.add_audit_log(
            actor="admin_tester",
            action="TEST_ACTION_CHAIN_2",
            target="SYSTEM",
            new_value="Test payload 2",
            ip="192.168.1.100"
        )

        res = DBManager.verify_audit_chain()
        print(f"Ket qua verify_audit_chain: {res}")
        self.assertTrue(res['is_valid'])
        self.assertIsNone(res['tampered_record_id'])
        self.assertGreaterEqual(res['total_records'], 3)
        print("OK: Chuoi Hash-Chain SHA-256 xac thuc thanh cong tuyet doi!")

    def test_05_quarantine_and_release_flow_without_tampering_radpostauth(self):
        """
        Kiểm tra toàn bộ luồng nghiệp vụ:
        1. User bị brute force 6 lần -> Detector quarantine user.
        2. Admin giải phóng user -> Ghi vào quarantine_events (RELEASE).
        3. radpostauth KHÔNG bị sửa, reply vẫn là 'Access-Reject'.
        4. Detector KHÔNG quarantine lại user sau giải phóng vì reject cũ nằm trước mốc RELEASE.
        """
        test_user = "sv_test"
        # Đảm bảo user ban đầu ở nhóm sinhvien
        try:
            self.ldap_client.unquarantine_user(test_user, "sinhvien")
        except Exception:
            pass

        # 1. Tạo 6 reject attempts
        with self.conn.cursor() as cursor:
            for _ in range(Config.BRUTEFORCE_THRESHOLD):
                cursor.execute("""
                    INSERT INTO radpostauth (username, pass, reply)
                    VALUES (%s, 'wrongpass', 'Access-Reject')
                """, (test_user,))

        # Chạy detector check
        detector_instance._check_bruteforce_attempts()

        # Kiểm tra user đã bị chuyển sang nhóm quarantine chưa
        grp_after_attack = self.ldap_client.get_user_group(test_user)
        self.assertEqual(grp_after_attack, "quarantine")
        print(f"OK: User {test_user} da bi quarantine tu dong!")

        # 2. Admin thực hiện unlock
        self.ldap_client.unquarantine_user(test_user, "sinhvien")
        detector_instance.recent_alerts = [a for a in detector_instance.recent_alerts if a.get('username') != test_user]
        DBManager.record_quarantine_event(
            username=test_user,
            event_type='RELEASE',
            reason="Giai phong qua test suite",
            failed_count=0,
            source="admin_test",
            previous_group="quarantine"
        )
        DBManager.add_audit_log(
            actor="admin_test",
            action="UNLOCK_USER",
            target=test_user,
            old_val="Group: quarantine",
            new_val="Group: sinhvien",
            ip="127.0.0.1"
        )

        # 3. Kiểm tra radpostauth: KHÔNG CÓ DÒNG NÀO BỊ ĐỔI THÀNH 'Access-Reject-Resolved'!
        with self.conn.cursor() as cursor:
            cursor.execute("""
                SELECT COUNT(*) as resolved_cnt 
                FROM radpostauth 
                WHERE username = %s AND reply = 'Access-Reject-Resolved'
            """, (test_user,))
            resolved_count = cursor.fetchone()['resolved_cnt']
            self.assertEqual(resolved_count, 0)

            cursor.execute("""
                SELECT COUNT(*) as reject_cnt 
                FROM radpostauth 
                WHERE username = %s AND reply = 'Access-Reject'
            """, (test_user,))
            reject_count = cursor.fetchone()['reject_cnt']
            self.assertGreaterEqual(reject_count, 6)
            print("OK: radpostauth hoan toan bat bien, khong bi sua thanh Resolved!")

        # 4. Chạy lại detector một lần nữa: User KHÔNG ĐƯỢC PHÉP bị quarantine lại!
        time.sleep(0.5)
        detector_instance._check_bruteforce_attempts()
        grp_after_check = self.ldap_client.get_user_group(test_user)
        self.assertEqual(grp_after_check, "sinhvien")
        print("OK: Detector nhan dien dung moc RELEASE va KHONG cach ly lai tai khoan!")

if __name__ == '__main__':
    unittest.main()
