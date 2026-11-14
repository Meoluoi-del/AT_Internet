import pymysql
from pymysql.cursors import DictCursor
from config import Config

def get_db_connection():
    return pymysql.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        cursorclass=DictCursor,
        autocommit=True
    )

class DBManager:
    @staticmethod
    def get_policies():
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM policy_matrix ORDER BY priority DESC")
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def update_policy(group_name: str, vlan_id: int, vlan_name: str, session_timeout: int, idle_timeout: int):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # 1. Update policy_matrix
                cursor.execute("""
                    UPDATE policy_matrix 
                    SET vlan_id = %s, vlan_name = %s, session_timeout = %s, idle_timeout = %s
                    WHERE group_name = %s
                """, (vlan_id, vlan_name, session_timeout, idle_timeout, group_name))
                
                # 2. Synchronize with FreeRADIUS radgroupreply table
                cursor.execute("""
                    UPDATE radgroupreply 
                    SET value = %s 
                    WHERE groupname = %s AND attribute = 'Tunnel-Private-Group-Id'
                """, (str(vlan_id), group_name))
                
                cursor.execute("""
                    UPDATE radgroupreply 
                    SET value = %s 
                    WHERE groupname = %s AND attribute = 'Session-Timeout'
                """, (str(session_timeout), group_name))
                
                cursor.execute("""
                    UPDATE radgroupreply 
                    SET value = %s 
                    WHERE groupname = %s AND attribute = 'Idle-Timeout'
                """, (str(idle_timeout), group_name))
                return True
        finally:
            conn.close()

    @staticmethod
    def get_auth_logs(limit: int = 100, username: str = None):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if username:
                    cursor.execute("""
                        SELECT * FROM radpostauth 
                        WHERE username LIKE %s 
                        ORDER BY authdate DESC LIMIT %s
                    """, (f"%{username}%", limit))
                else:
                    cursor.execute("""
                        SELECT * FROM radpostauth 
                        ORDER BY authdate DESC LIMIT %s
                    """, (limit,))
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def get_active_sessions():
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT * FROM radacct 
                    WHERE acctstoptime IS NULL 
                    ORDER BY acctstarttime DESC LIMIT 100
                """)
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def get_audit_logs(limit: int = 100):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT %s", (limit,))
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def add_audit_log(actor: str, action: str, target: str, old_val: str = "", new_val: str = "", ip: str = "127.0.0.1", old_value: str = "", new_value: str = ""):
        conn = get_db_connection()
        try:
            final_old = old_val or old_value or ""
            final_new = new_val or new_value or ""
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO audit_logs (actor_username, action, target, old_value, new_value, ip_address)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (actor, action, target, final_old, final_new, ip))
        finally:
            conn.close()

    @staticmethod
    def get_stats():
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) as count FROM radpostauth WHERE DATE(authdate) = CURDATE()")
                today_auths = cursor.fetchone()['count']
                
                cursor.execute("SELECT COUNT(*) as count FROM radpostauth WHERE reply = 'Access-Reject' AND DATE(authdate) = CURDATE()")
                today_rejects = cursor.fetchone()['count']

                cursor.execute("SELECT COUNT(*) as count FROM policy_matrix WHERE is_active = 1")
                active_policies = cursor.fetchone()['count']
                
                return {
                    'today_auths': today_auths,
                    'today_rejects': today_rejects,
                    'active_policies': active_policies
                }
        finally:
            conn.close()

    # ====================================================================
    # MFA / 2FA METHODS (XÁC THỰC ĐA NHÂN TỐ TOTP)
    # ====================================================================
    @staticmethod
    def get_user_mfa(username: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM user_mfa WHERE username = %s", (username,))
                return cursor.fetchone()
        finally:
            conn.close()

    @staticmethod
    def save_user_mfa(username: str, secret_key: str, is_enabled: int = 0):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO user_mfa (username, secret_key, is_enabled)
                    VALUES (%s, %s, %s)
                    ON DUPLICATE KEY UPDATE secret_key = VALUES(secret_key), is_enabled = VALUES(is_enabled)
                """, (username, secret_key, is_enabled))
                return True
        finally:
            conn.close()

    @staticmethod
    def enable_user_mfa(username: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE user_mfa SET is_enabled = 1 WHERE username = %s", (username,))
                return True
        finally:
            conn.close()

    @staticmethod
    def disable_user_mfa(username: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE user_mfa SET is_enabled = 0 WHERE username = %s", (username,))
                return True
        finally:
            conn.close()

    @staticmethod
    def check_mfa_lock(username: str) -> dict:
        """Kiểm tra xem tài khoản có đang bị tạm khóa xác thực MFA hay không."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT failed_otp_attempts, otp_locked_until, 
                           TIMESTAMPDIFF(SECOND, NOW(), otp_locked_until) AS seconds_left
                    FROM user_mfa WHERE username = %s
                """, (username,))
                row = cursor.fetchone()
                if not row:
                    return {'is_locked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
                
                seconds_left = row.get('seconds_left')
                if seconds_left is not None and seconds_left > 0:
                    minutes_left = max(1, (seconds_left + 59) // 60)
                    return {
                        'is_locked': True,
                        'seconds_left': seconds_left,
                        'minutes_left': minutes_left,
                        'failed_attempts': row.get('failed_otp_attempts', 0)
                    }
                elif row.get('otp_locked_until') is not None:
                    # Thời gian khóa 10 phút đã hết -> tự động giải phóng khóa
                    cursor.execute("""
                        UPDATE user_mfa 
                        SET failed_otp_attempts = 0, otp_locked_until = NULL 
                        WHERE username = %s
                    """, (username,))
                    return {'is_locked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
                
                return {
                    'is_locked': False,
                    'seconds_left': 0,
                    'minutes_left': 0,
                    'failed_attempts': row.get('failed_otp_attempts', 0) or 0
                }
        finally:
            conn.close()

    @staticmethod
    def record_mfa_failed_attempt(username: str, max_attempts: int = 3, lock_minutes: int = 10) -> dict:
        """Ghi nhận lần nhập sai mã OTP. Nếu sai >= max_attempts (3 lần) thì khóa lock_minutes (10 phút)."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT failed_otp_attempts FROM user_mfa WHERE username = %s", (username,))
                row = cursor.fetchone()
                current_fails = (row['failed_otp_attempts'] or 0) if row else 0
                new_fails = current_fails + 1
                
                if new_fails >= max_attempts:
                    cursor.execute("""
                        UPDATE user_mfa 
                        SET failed_otp_attempts = %s,
                            otp_locked_until = DATE_ADD(NOW(), INTERVAL %s MINUTE)
                        WHERE username = %s
                    """, (new_fails, lock_minutes, username))
                    return {
                        'is_locked': True,
                        'failed_attempts': new_fails,
                        'remaining_attempts': 0,
                        'lock_minutes': lock_minutes
                    }
                else:
                    cursor.execute("""
                        UPDATE user_mfa 
                        SET failed_otp_attempts = %s 
                        WHERE username = %s
                    """, (new_fails, username))
                    return {
                        'is_locked': False,
                        'failed_attempts': new_fails,
                        'remaining_attempts': max_attempts - new_fails,
                        'lock_minutes': lock_minutes
                    }
        finally:
            conn.close()

    @staticmethod
    def record_mfa_success(username: str, matched_step: int = None):
        """Xác thực MFA thành công: reset số lần sai, xóa khóa, cập nhật last_verified_step để chống Replay."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE user_mfa 
                    SET failed_otp_attempts = 0,
                        otp_locked_until = NULL,
                        last_used_at = NOW(),
                        last_verified_step = COALESCE(%s, last_verified_step)
                    WHERE username = %s
                """, (matched_step, username))
                return True
        finally:
            conn.close()

    @staticmethod
    def record_mfa_use(username: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE user_mfa SET last_used_at = NOW() WHERE username = %s", (username,))
                return True
        finally:
            conn.close()

    # ====================================================================
    # SSO / OIDC METHODS (SINGLE SIGN-ON TẬP TRUNG)
    # ====================================================================
    @staticmethod
    def get_sso_clients():
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM sso_clients WHERE is_active = 1 ORDER BY id ASC")
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def get_sso_client(client_id: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM sso_clients WHERE client_id = %s AND is_active = 1", (client_id,))
                return cursor.fetchone()
        finally:
            conn.close()

    @staticmethod
    def create_auth_code(client_id: str, username: str, redirect_uri: str, expires_in_sec: int = 300) -> str:
        import secrets
        code = secrets.token_urlsafe(32)
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO sso_auth_codes (code, client_id, username, redirect_uri, expires_at)
                    VALUES (%s, %s, %s, %s, DATE_ADD(NOW(), INTERVAL %s SECOND))
                """, (code, client_id, username, redirect_uri, expires_in_sec))
                return code
        finally:
            conn.close()

    @staticmethod
    def consume_auth_code(code: str, client_id: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT * FROM sso_auth_codes 
                    WHERE code = %s AND client_id = %s AND expires_at > NOW()
                """, (code, client_id))
                record = cursor.fetchone()
                if record:
                    cursor.execute("DELETE FROM sso_auth_codes WHERE code = %s", (code,))
                    return record
                return None
        finally:
            conn.close()
