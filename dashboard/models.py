import hashlib
from datetime import datetime
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
    def compute_record_hash(prev_hash: str, actor: str, action: str, target: str, old_val: str, new_val: str, ip: str, created_at: str) -> str:
        """
        Tính toán SHA-256 hash cho bản ghi audit log.
        Bao gồm toàn bộ dữ liệu nghiệp vụ và prev_hash để tạo thành chuỗi liên kết (Hash-Chain).
        """
        raw_payload = f"{prev_hash}|{actor}|{action}|{target}|{old_val or ''}|{new_val or ''}|{ip}|{created_at}"
        return hashlib.sha256(raw_payload.encode('utf-8')).hexdigest()

    @staticmethod
    def add_audit_log(actor: str, action: str, target: str, old_val: str = "", new_val: str = "", ip: str = "127.0.0.1", old_value: str = "", new_value: str = ""):
        conn = get_db_connection()
        try:
            final_old = old_val or old_value or ""
            final_new = new_val or new_value or ""
            now_dt = datetime.now()
            created_at_str = now_dt.strftime('%Y-%m-%d %H:%M:%S')

            with conn.cursor() as cursor:
                # Lấy record_hash của bản ghi gần nhất để tạo liên kết Hash-Chain
                cursor.execute("SELECT record_hash FROM audit_logs ORDER BY id DESC LIMIT 1")
                last_record = cursor.fetchone()
                
                if last_record and last_record.get('record_hash') and last_record['record_hash'] != '0'*64:
                    prev_hash = last_record['record_hash']
                else:
                    prev_hash = '0' * 64
                
                record_hash = DBManager.compute_record_hash(
                    prev_hash=prev_hash,
                    actor=actor,
                    action=action,
                    target=target,
                    old_val=final_old,
                    new_val=final_new,
                    ip=ip,
                    created_at=created_at_str
                )

                cursor.execute("""
                    INSERT INTO audit_logs (actor_username, action, target, old_value, new_value, ip_address, created_at, prev_hash, record_hash)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (actor, action, target, final_old, final_new, ip, created_at_str, prev_hash, record_hash))
        finally:
            conn.close()

    @staticmethod
    def verify_audit_chain():
        """
        Xác minh tính toàn vẹn của chuỗi Hash-Chain trong audit_logs.
        Kiểm tra:
        1. Liên kết prev_hash giữa các block liên tiếp (Chain continuity).
        2. Tính khớp của dữ liệu nội dung với record_hash (Data integrity & non-repudiation).
        """
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id, actor_username, action, target, old_value, new_value, 
                           ip_address, created_at, prev_hash, record_hash
                    FROM audit_logs
                    ORDER BY id ASC
                """)
                rows = cursor.fetchall()

                if not rows:
                    return {'is_valid': True, 'total_records': 0, 'tampered_record_id': None, 'message': 'Chưa có bản ghi audit nào.'}

                expected_prev = '0' * 64
                for row in rows:
                    row_id = row['id']
                    # 1. Kiểm tra prev_hash có khớp với hash bản ghi trước không
                    if row['prev_hash'] != expected_prev:
                        return {
                            'is_valid': False,
                            'total_records': len(rows),
                            'tampered_record_id': row_id,
                            'message': f"Lỗi liên kết chuỗi tại Record #{row_id}: prev_hash ({row['prev_hash'][:16]}...) không khớp ({expected_prev[:16]}...)"
                        }

                    # 2. Định dạng created_at
                    cat = row['created_at']
                    if hasattr(cat, 'strftime'):
                        created_at_str = cat.strftime('%Y-%m-%d %H:%M:%S')
                    else:
                        created_at_str = str(cat)

                    # 3. Tính lại hash
                    recomputed = DBManager.compute_record_hash(
                        prev_hash=row['prev_hash'],
                        actor=row['actor_username'],
                        action=row['action'],
                        target=row['target'],
                        old_val=row['old_value'] or '',
                        new_val=row['new_value'] or '',
                        ip=row['ip_address'],
                        created_at=created_at_str
                    )

                    if recomputed != row['record_hash']:
                        return {
                            'is_valid': False,
                            'total_records': len(rows),
                            'tampered_record_id': row_id,
                            'message': f"Bản ghi Record #{row_id} đã bị làm giả hoặc sửa đổi! Recomputed ({recomputed[:16]}...) != stored ({row['record_hash'][:16]}...)"
                        }

                    expected_prev = row['record_hash']

                return {
                    'is_valid': True,
                    'total_records': len(rows),
                    'tampered_record_id': None,
                    'message': f"Toàn bộ {len(rows)} bản ghi audit log hoàn toàn nguyên vẹn, chuỗi hash SHA-256 hợp lệ."
                }
        finally:
            conn.close()

    @staticmethod
    def record_quarantine_event(username: str, event_type: str, reason: str = "", failed_count: int = 0, source: str = "SYSTEM_ACTIVE_DEFENSE", previous_group: str = None):
        """Ghi nhận sự kiện cách ly (QUARANTINE) hoặc giải phóng (RELEASE) vào bảng quarantine_events (Append-only)."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO quarantine_events (username, event_type, reason, failed_count, source, previous_group)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (username, event_type, reason, failed_count, source, previous_group))
        finally:
            conn.close()

    @staticmethod
    def get_quarantine_events(username: str = None, limit: int = 50):
        """Lấy lịch sử sự kiện cách ly và giải phóng."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if username:
                    cursor.execute("""
                        SELECT * FROM quarantine_events
                        WHERE username = %s
                        ORDER BY event_time DESC LIMIT %s
                    """, (username, limit))
                else:
                    cursor.execute("""
                        SELECT * FROM quarantine_events
                        ORDER BY event_time DESC LIMIT %s
                    """, (limit,))
                return cursor.fetchall()
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
    # DASHBOARD LOGIN BRUTE-FORCE PROTECTION (KHÓA KÉP TÀI KHOẢN & CHẶN IP)
    # ====================================================================
    @staticmethod
    def check_dashboard_ip_lock(ip_address: str) -> dict:
        """Kiểm tra xem địa chỉ IP có đang bị tạm chặn đăng nhập hay không."""
        if not ip_address:
            return {'is_blocked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT failed_attempts, blocked_until, 
                           TIMESTAMPDIFF(SECOND, NOW(), blocked_until) AS seconds_left
                    FROM dashboard_ip_lockouts WHERE ip_address = %s
                """, (ip_address,))
                row = cursor.fetchone()
                if not row:
                    return {'is_blocked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
                
                seconds_left = row.get('seconds_left')
                if seconds_left is not None and seconds_left > 0:
                    minutes_left = max(1, (seconds_left + 59) // 60)
                    return {
                        'is_blocked': True,
                        'seconds_left': seconds_left,
                        'minutes_left': minutes_left,
                        'failed_attempts': row.get('failed_attempts', 0)
                    }
                elif row.get('blocked_until') is not None:
                    # Hết thời gian chặn -> Tự động giải phóng
                    cursor.execute("""
                        UPDATE dashboard_ip_lockouts 
                        SET failed_attempts = 0, blocked_until = NULL 
                        WHERE ip_address = %s
                    """, (ip_address,))
                    return {'is_blocked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
                
                return {
                    'is_blocked': False,
                    'seconds_left': 0,
                    'minutes_left': 0,
                    'failed_attempts': row.get('failed_attempts', 0) or 0
                }
        finally:
            conn.close()

    @staticmethod
    def check_dashboard_account_lock(username: str) -> dict:
        """Kiểm tra xem tài khoản quản trị có đang bị tạm khóa hay không."""
        if not username:
            return {'is_locked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT failed_attempts, locked_until, 
                           TIMESTAMPDIFF(SECOND, NOW(), locked_until) AS seconds_left
                    FROM dashboard_account_lockouts WHERE username = %s
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
                        'failed_attempts': row.get('failed_attempts', 0)
                    }
                elif row.get('locked_until') is not None:
                    # Hết thời gian khóa -> Tự động giải phóng
                    cursor.execute("""
                        UPDATE dashboard_account_lockouts 
                        SET failed_attempts = 0, locked_until = NULL 
                        WHERE username = %s
                    """, (username,))
                    return {'is_locked': False, 'seconds_left': 0, 'minutes_left': 0, 'failed_attempts': 0}
                
                return {
                    'is_locked': False,
                    'seconds_left': 0,
                    'minutes_left': 0,
                    'failed_attempts': row.get('failed_attempts', 0) or 0
                }
        finally:
            conn.close()

    @staticmethod
    def record_dashboard_ip_failure(ip_address: str, target_user: str = "UNKNOWN", max_attempts: int = 5, lock_minutes: int = 60) -> dict:
        """
        Ghi nhận lần đăng nhập sai của IP khi thử username không tồn tại trong hệ thống.
        Chỉ theo dõi và khóa IP, tuyệt đối không tạo bản ghi khóa cho tài khoản không tồn tại.
        """
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                new_ip_fails = 1
                if ip_address:
                    cursor.execute("SELECT failed_attempts FROM dashboard_ip_lockouts WHERE ip_address = %s", (ip_address,))
                    row_ip = cursor.fetchone()
                    if row_ip:
                        new_ip_fails = (row_ip['failed_attempts'] or 0) + 1
                    
                    if new_ip_fails >= max_attempts:
                        cursor.execute("""
                            INSERT INTO dashboard_ip_lockouts (ip_address, failed_attempts, blocked_until, last_attempt_at, last_target_user)
                            VALUES (%s, %s, DATE_ADD(NOW(), INTERVAL %s MINUTE), NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                blocked_until = VALUES(blocked_until),
                                last_attempt_at = VALUES(last_attempt_at),
                                last_target_user = VALUES(last_target_user)
                        """, (ip_address, new_ip_fails, lock_minutes, target_user))
                    else:
                        cursor.execute("""
                            INSERT INTO dashboard_ip_lockouts (ip_address, failed_attempts, blocked_until, last_attempt_at, last_target_user)
                            VALUES (%s, %s, NULL, NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                last_attempt_at = VALUES(last_attempt_at),
                                last_target_user = VALUES(last_target_user)
                        """, (ip_address, new_ip_fails, target_user))

                is_blocked = (new_ip_fails >= max_attempts)
                return {
                    'is_blocked': is_blocked,
                    'failed_attempts': new_ip_fails,
                    'remaining_attempts': max(0, max_attempts - new_ip_fails),
                    'lock_minutes': lock_minutes
                }
        finally:
            conn.close()

    @staticmethod
    def record_dashboard_login_failure(username: str, ip_address: str, max_attempts: int = 5, lock_minutes: int = 60) -> dict:
        """
        Ghi nhận lần đăng nhập sai.
        Cập nhật đồng thời cho cả Tài khoản (username) và Địa chỉ IP (ip_address).
        Nếu số lần thử sai >= max_attempts (5 lần) -> Khóa kép cả Tài khoản và IP trong lock_minutes (60 phút = 1 tiếng).
        """
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # 1. Cập nhật cho tài khoản username (nếu có username)
                new_acc_fails = 1
                if username:
                    cursor.execute("SELECT failed_attempts FROM dashboard_account_lockouts WHERE username = %s", (username,))
                    row_acc = cursor.fetchone()
                    if row_acc:
                        new_acc_fails = (row_acc['failed_attempts'] or 0) + 1
                    
                    if new_acc_fails >= max_attempts:
                        cursor.execute("""
                            INSERT INTO dashboard_account_lockouts (username, failed_attempts, locked_until, last_failed_at, last_failed_ip)
                            VALUES (%s, %s, DATE_ADD(NOW(), INTERVAL %s MINUTE), NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                locked_until = VALUES(locked_until),
                                last_failed_at = VALUES(last_failed_at),
                                last_failed_ip = VALUES(last_failed_ip)
                        """, (username, new_acc_fails, lock_minutes, ip_address))
                    else:
                        cursor.execute("""
                            INSERT INTO dashboard_account_lockouts (username, failed_attempts, locked_until, last_failed_at, last_failed_ip)
                            VALUES (%s, %s, NULL, NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                last_failed_at = VALUES(last_failed_at),
                                last_failed_ip = VALUES(last_failed_ip)
                        """, (username, new_acc_fails, ip_address))

                # 2. Cập nhật cho IP ip_address
                new_ip_fails = 1
                if ip_address:
                    cursor.execute("SELECT failed_attempts FROM dashboard_ip_lockouts WHERE ip_address = %s", (ip_address,))
                    row_ip = cursor.fetchone()
                    if row_ip:
                        new_ip_fails = (row_ip['failed_attempts'] or 0) + 1
                    
                    if new_ip_fails >= max_attempts or new_acc_fails >= max_attempts:
                        cursor.execute("""
                            INSERT INTO dashboard_ip_lockouts (ip_address, failed_attempts, blocked_until, last_attempt_at, last_target_user)
                            VALUES (%s, %s, DATE_ADD(NOW(), INTERVAL %s MINUTE), NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                blocked_until = VALUES(blocked_until),
                                last_attempt_at = VALUES(last_attempt_at),
                                last_target_user = VALUES(last_target_user)
                        """, (ip_address, new_ip_fails, lock_minutes, username))
                    else:
                        cursor.execute("""
                            INSERT INTO dashboard_ip_lockouts (ip_address, failed_attempts, blocked_until, last_attempt_at, last_target_user)
                            VALUES (%s, %s, NULL, NOW(), %s)
                            ON DUPLICATE KEY UPDATE 
                                failed_attempts = VALUES(failed_attempts),
                                last_attempt_at = VALUES(last_attempt_at),
                                last_target_user = VALUES(last_target_user)
                        """, (ip_address, new_ip_fails, username))

                effective_fails = max(new_acc_fails, new_ip_fails)
                is_locked = (effective_fails >= max_attempts)
                return {
                    'is_locked': is_locked,
                    'failed_attempts': effective_fails,
                    'remaining_attempts': max(0, max_attempts - effective_fails),
                    'lock_minutes': lock_minutes
                }
        finally:
            conn.close()

    @staticmethod
    def record_dashboard_login_success(username: str, ip_address: str):
        """Đăng nhập thành công: giải phóng số lần sai của tài khoản và địa chỉ IP."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if username:
                    cursor.execute("""
                        UPDATE dashboard_account_lockouts 
                        SET failed_attempts = 0, locked_until = NULL 
                        WHERE username = %s
                    """, (username,))
                if ip_address:
                    cursor.execute("""
                        UPDATE dashboard_ip_lockouts 
                        SET failed_attempts = 0, blocked_until = NULL 
                        WHERE ip_address = %s
                    """, (ip_address,))
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
    def create_auth_code(client_id: str, username: str, redirect_uri: str, code_challenge: str = None, code_challenge_method: str = None, nonce: str = None, expires_in_sec: int = 300) -> str:
        import secrets
        code = secrets.token_urlsafe(32)
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO sso_auth_codes (code, client_id, username, redirect_uri, code_challenge, code_challenge_method, nonce, expires_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, DATE_ADD(NOW(), INTERVAL %s SECOND))
                """, (code, client_id, username, redirect_uri, code_challenge, code_challenge_method, nonce, expires_in_sec))
                return code
        finally:
            conn.close()

    @staticmethod
    def update_sso_client_secret(client_id: str, hashed_secret: str):
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE sso_clients SET client_secret = %s WHERE client_id = %s
                """, (hashed_secret, client_id))
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

    # ====================================================================
    # SINGLE LOGOUT (SLO) & SESSION REPLAY DEFENSE METHODS
    # ====================================================================
    @staticmethod
    def record_sso_master_session(session_id: str, username: str, ip_address: str = None, user_agent: str = None):
        """Ghi nhận hoặc làm mới phiên SSO Master trung tâm."""
        if not session_id or not username:
            return False
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO sso_sessions (session_id, username, ip_address, user_agent, is_active, last_activity)
                    VALUES (%s, %s, %s, %s, 1, NOW())
                    ON DUPLICATE KEY UPDATE 
                        username = VALUES(username),
                        ip_address = VALUES(ip_address),
                        user_agent = VALUES(user_agent),
                        is_active = 1,
                        logged_out_at = NULL,
                        last_activity = NOW()
                """, (session_id, username, ip_address, user_agent))
                conn.commit()
                return True
        finally:
            conn.close()

    @staticmethod
    def get_sso_master_session(session_id: str):
        """Lấy thông tin phiên Master từ DB nếu còn hiệu lực (is_active=1 và logged_out_at IS NULL)."""
        if not session_id:
            return None
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT session_id, username, ip_address, user_agent, is_active, logged_out_at
                    FROM sso_sessions 
                    WHERE session_id = %s AND is_active = 1 AND logged_out_at IS NULL
                """, (session_id,))
                return cursor.fetchone()
        finally:
            conn.close()

    @staticmethod
    def record_sso_client_session(session_id: str, client_id: str, username: str, access_token_jti: str = None):
        """Ghi nhận phiên ứng dụng vệ tinh liên kết với phiên SSO trung tâm."""
        if not session_id or not client_id or not username:
            return False
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO sso_sessions (session_id, username, is_active, last_activity)
                    VALUES (%s, %s, 1, NOW())
                    ON DUPLICATE KEY UPDATE is_active = 1, last_activity = NOW()
                """, (session_id, username))
                
                cursor.execute("""
                    INSERT INTO sso_client_sessions (session_id, client_id, username, access_token_jti, is_active)
                    VALUES (%s, %s, %s, %s, 1)
                """, (session_id, client_id, username, access_token_jti))
                conn.commit()
                return True
        finally:
            conn.close()

    @staticmethod
    def get_active_sso_client_apps(session_id: str) -> list:
        """Lấy danh sách các ứng dụng Client đang có phiên hoạt động gắn với session_id."""
        if not session_id:
            return []
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT DISTINCT c.client_id, c.client_name, c.icon_class
                    FROM sso_client_sessions cs
                    JOIN sso_clients c ON cs.client_id = c.client_id
                    WHERE cs.session_id = %s AND cs.is_active = 1 AND cs.revoked_at IS NULL
                    ORDER BY cs.id ASC
                """, (session_id,))
                return cursor.fetchall()
        finally:
            conn.close()

    @staticmethod
    def is_sso_session_valid(session_id: str = None, client_id: str = None, jti: str = None) -> bool:
        """
        Kiểm tra tính hợp lệ của phiên làm việc (Chống Session Replay Attack).
        Nếu phiên Master hoặc Client đã bị hủy qua Single Logout -> Trả về False.
        """
        if not session_id and not jti:
            return False
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # 1. Kiểm tra trạng thái master session nếu có session_id
                if session_id:
                    cursor.execute("""
                        SELECT is_active, logged_out_at FROM sso_sessions WHERE session_id = %s
                    """, (session_id,))
                    m_row = cursor.fetchone()
                    if not m_row or m_row.get('is_active') != 1 or m_row.get('logged_out_at') is not None:
                        return False
                
                # 2. Nếu có client_id và session_id, kiểm tra client session tương ứng
                if session_id and client_id:
                    cursor.execute("""
                        SELECT is_active, revoked_at FROM sso_client_sessions
                        WHERE session_id = %s AND client_id = %s
                        ORDER BY id DESC LIMIT 1
                    """, (session_id, client_id))
                    c_row = cursor.fetchone()
                    if c_row and (c_row.get('is_active') != 1 or c_row.get('revoked_at') is not None):
                        return False
                
                # 3. Nếu có jti của token, kiểm tra xem token jti và master session liên quan có bị thu hồi không
                if jti:
                    cursor.execute("""
                        SELECT cs.is_active, cs.revoked_at, s.is_active as master_active, s.logged_out_at
                        FROM sso_client_sessions cs
                        LEFT JOIN sso_sessions s ON cs.session_id = s.session_id
                        WHERE cs.access_token_jti = %s
                        ORDER BY cs.id DESC LIMIT 1
                    """, (jti,))
                    j_row = cursor.fetchone()
                    if j_row:
                        if j_row.get('is_active') != 1 or j_row.get('revoked_at') is not None:
                            return False
                        if j_row.get('master_active') == 0 or j_row.get('logged_out_at') is not None:
                            return False

                return True
        finally:
            conn.close()

    @staticmethod
    def terminate_sso_single_logout(session_id: str = None, username: str = None) -> int:
        """
        Thực hiện Single Logout (SLO):
        Hủy toàn bộ phiên Master và tất cả các phiên Client liên kết.
        Trả về số lượng ứng dụng đã được thu hồi phiên.
        """
        conn = get_db_connection()
        revoked_count = 0
        try:
            with conn.cursor() as cursor:
                if session_id:
                    cursor.execute("""
                        UPDATE sso_sessions 
                        SET is_active = 0, logged_out_at = NOW() 
                        WHERE session_id = %s
                    """, (session_id,))
                    cursor.execute("""
                        UPDATE sso_client_sessions 
                        SET is_active = 0, revoked_at = NOW() 
                        WHERE session_id = %s AND is_active = 1
                    """, (session_id,))
                    revoked_count = cursor.rowcount
                elif username:
                    cursor.execute("""
                        UPDATE sso_sessions 
                        SET is_active = 0, logged_out_at = NOW() 
                        WHERE username = %s
                    """, (username,))
                    cursor.execute("""
                        UPDATE sso_client_sessions 
                        SET is_active = 0, revoked_at = NOW() 
                        WHERE username = %s AND is_active = 1
                    """, (username,))
                    revoked_count = cursor.rowcount
                conn.commit()
                return revoked_count
        finally:
            conn.close()

    # ====================================================================
    # QUARANTINE IP LOCKOUT & RELEASE METHODS
    # ====================================================================
    @staticmethod
    def block_user_ip(username: str, lock_minutes: int = 1440) -> list:
        """Thu thập tất cả IP mà user từng sử dụng (từ sso_sessions, radacct, audit_logs) và khóa lại."""
        conn = get_db_connection()
        blocked_ips = set()
        try:
            with conn.cursor() as cursor:
                # 1. Tìm IP từ sso_sessions
                try:
                    cursor.execute("SELECT ip_address FROM sso_sessions WHERE username = %s AND ip_address IS NOT NULL", (username,))
                    for r in cursor.fetchall():
                        ip = r['ip_address']
                        if ip and ip not in {'127.0.0.1', 'localhost', '::1'}:
                            blocked_ips.add(ip)
                except Exception:
                    pass

                # 2. Tìm IP từ audit_logs
                try:
                    cursor.execute("SELECT ip_address FROM audit_logs WHERE actor_username = %s AND ip_address IS NOT NULL", (username,))
                    for r in cursor.fetchall():
                        ip = r['ip_address']
                        if ip and ip not in {'127.0.0.1', 'localhost', '::1'}:
                            blocked_ips.add(ip)
                except Exception:
                    pass

                # 3. Ghi nhận chặn các IP này vào bảng dashboard_ip_lockouts
                for ip in blocked_ips:
                    cursor.execute("""
                        INSERT INTO dashboard_ip_lockouts (ip_address, failed_attempts, blocked_until, last_attempt_at, last_target_user)
                        VALUES (%s, 5, DATE_ADD(NOW(), INTERVAL %s MINUTE), NOW(), %s)
                        ON DUPLICATE KEY UPDATE 
                            blocked_until = DATE_ADD(NOW(), INTERVAL %s MINUTE),
                            last_target_user = %s,
                            failed_attempts = 5
                    """, (ip, lock_minutes, username, lock_minutes, username))
                conn.commit()
            return list(blocked_ips)
        finally:
            conn.close()

    @staticmethod
    def unblock_user_ip(username: str) -> list:
        """Giải phóng toàn bộ địa chỉ IP liên kết với tài khoản khi tài khoản được mở khóa."""
        conn = get_db_connection()
        unblocked_ips = []
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT ip_address FROM dashboard_ip_lockouts 
                    WHERE last_target_user = %s
                """, (username,))
                rows = cursor.fetchall()
                unblocked_ips = [r['ip_address'] for r in rows]

                if unblocked_ips:
                    cursor.execute("""
                        DELETE FROM dashboard_ip_lockouts 
                        WHERE last_target_user = %s
                    """, (username,))
                    conn.commit()
            return unblocked_ips
        finally:
            conn.close()

    # ====================================================================
    # PASSWORD RESET VIA EMAIL (QUẢN LÝ TOKEN ĐẶT LẠI MẬT KHẨU)
    # ====================================================================
    @staticmethod
    def create_password_reset_token(username: str, email: str, raw_token: str, expires_minutes: int = 15, ip_address: str = None) -> int:
        """Tạo token đặt lại mật khẩu với thời hạn expires_minutes và lưu hash SHA-256."""
        token_hash = hashlib.sha256(raw_token.encode('utf-8')).hexdigest()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # Vô hiệu hóa các token cũ chưa sử dụng của user này
                cursor.execute("""
                    UPDATE password_reset_tokens 
                    SET is_used = 1, used_at = NOW() 
                    WHERE username = %s AND is_used = 0
                """, (username,))
                
                cursor.execute("""
                    INSERT INTO password_reset_tokens (username, email, token_hash, expires_at, ip_address)
                    VALUES (%s, %s, %s, DATE_ADD(NOW(), INTERVAL %s MINUTE), %s)
                """, (username, email, token_hash, expires_minutes, ip_address))
                conn.commit()
                return cursor.lastrowid
        finally:
            conn.close()

    @staticmethod
    def verify_password_reset_token(raw_token: str) -> dict:
        """
        Xác thực tính hợp lệ của token đặt lại mật khẩu:
        - Khớp hash SHA-256
        - Chưa bị sử dụng (is_used = 0)
        - Chưa hết hạn (expires_at > NOW())
        """
        if not raw_token or not isinstance(raw_token, str):
            return None
        token_hash = hashlib.sha256(raw_token.encode('utf-8')).hexdigest()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id, username, email, expires_at, is_used,
                           TIMESTAMPDIFF(SECOND, NOW(), expires_at) AS seconds_left
                    FROM password_reset_tokens
                    WHERE token_hash = %s
                """, (token_hash,))
                row = cursor.fetchone()
                if not row:
                    return None
                if row.get('is_used') == 1:
                    return {'valid': False, 'reason': 'used', 'username': row['username']}
                if (row.get('seconds_left') is not None and row.get('seconds_left') <= 0):
                    return {'valid': False, 'reason': 'expired', 'username': row['username']}
                return {
                    'valid': True,
                    'token_id': row['id'],
                    'username': row['username'],
                    'email': row['email'],
                    'seconds_left': row.get('seconds_left', 0)
                }
        finally:
            conn.close()

    @staticmethod
    def mark_password_reset_token_used(token_id: int) -> bool:
        """Đánh dấu token đặt lại mật khẩu đã sử dụng xong."""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE password_reset_tokens 
                    SET is_used = 1, used_at = NOW() 
                    WHERE id = %s
                """, (token_id,))
                conn.commit()
                return True
        finally:
            conn.close()
