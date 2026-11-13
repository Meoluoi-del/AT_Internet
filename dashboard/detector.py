import time
import threading
import logging
from datetime import datetime, timedelta
from config import Config
from models import DBManager, get_db_connection
from ldap_client import LDAPClient

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

class ActiveDefenseDetector:
    def __init__(self):
        self.running = False
        self.thread = None
        self.ldap_client = LDAPClient()
        self.recent_alerts = []

    def start(self):
        if not self.running:
            self.running = True
            self.thread = threading.Thread(target=self._monitor_loop, daemon=True)
            self.thread.start()
            logging.info("Active Defense Brute-force Detector thread started.")

    def _monitor_loop(self):
        while self.running:
            try:
                self._check_bruteforce_attempts()
            except Exception as e:
                logging.error(f"Error in Active Defense monitor: {e}")
            time.sleep(2)  # Check every 2 seconds for ultra-responsive defense

    def _check_bruteforce_attempts(self):
        conn = None
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Query failed attempts in the last window seconds (e.g. 180s)
                cursor.execute("""
                    SELECT username, COUNT(*) as failed_count, MAX(authdate) as last_attempt
                    FROM radpostauth
                    WHERE reply = 'Access-Reject'
                      AND authdate >= NOW() - INTERVAL %s SECOND
                    GROUP BY username
                    HAVING failed_count >= %s
                """, (Config.BRUTEFORCE_WINDOW_SECONDS, Config.BRUTEFORCE_THRESHOLD))
                suspicious_users = cursor.fetchall()

                for row in suspicious_users:
                    username = row['username']
                    count = row['failed_count']
                    
                    # Ignore empty or service accounts
                    if not username or username in ['radius-svc', 'admin01']:
                        continue

                    # Check current group of user in LDAP
                    current_group = self.ldap_client.get_user_group(username)
                    if current_group and current_group != 'quarantine':
                        logging.warning(f"[ACTIVE DEFENSE] Detected Brute-Force on user '{username}' ({count} failed attempts >= {Config.BRUTEFORCE_THRESHOLD}). Quarantining...")
                        
                        # 1. Move to quarantine group in LDAP
                        self.ldap_client.quarantine_user(username)
                        
                        # 2. Record in Audit Log
                        DBManager.add_audit_log(
                            actor="SYSTEM_ACTIVE_DEFENSE",
                            action="AUTO_QUARANTINE_BRUTEFORCE",
                            target=username,
                            old_val=f"Group: {current_group}",
                            new_val="Group: quarantine (VLAN 99)",
                            ip="127.0.0.1"
                        )
                        
                        # 3. Add to recent alerts
                        alert_msg = {
                            'username': username,
                            'failed_count': count,
                            'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                            'action': 'Đã tự động cô lập vào nhóm quarantine (VLAN 99)'
                        }
                        self.recent_alerts.insert(0, alert_msg)
                        if len(self.recent_alerts) > 20:
                            self.recent_alerts.pop()
                    elif current_group == 'quarantine':
                        # Nếu tài khoản đã bị cô lập nhưng kẻ tấn công vẫn tiếp tục thử sai:
                        # Cập nhật số đếm failed_count mới nhất vào recent_alerts để UI nhảy số thời gian thực
                        found = False
                        for alert in self.recent_alerts:
                            if alert['username'] == username:
                                alert['failed_count'] = count
                                found = True
                                break
                        if not found:
                            self.recent_alerts.insert(0, {
                                'username': username,
                                'failed_count': count,
                                'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                'action': 'Đang bị tấn công liên tục & đã bị giam giữ tại VLAN 99'
                            })
        except Exception as ex:
            logging.error(f"[ACTIVE DEFENSE ERROR] Exception in _check_bruteforce_attempts: {ex}", exc_info=True)
        finally:
            if conn:
                conn.close()

    def get_live_attacks(self):
        """Lấy danh sách chi tiết các cuộc tấn công đang diễn ra trong cửa sổ 180s."""
        conn = None
        attacks = []
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT username, COUNT(*) as failed_count, MAX(authdate) as last_attempt
                    FROM radpostauth
                    WHERE reply = 'Access-Reject'
                      AND authdate >= NOW() - INTERVAL %s SECOND
                    GROUP BY username
                    ORDER BY last_attempt DESC
                """, (Config.BRUTEFORCE_WINDOW_SECONDS,))
                rows = cursor.fetchall()
                for r in rows:
                    u = r['username']
                    if not u or u in ['radius-svc', 'admin01']:
                        continue
                    
                    grp = self.ldap_client.get_user_group(u)
                    is_quarantined = (grp == 'quarantine')
                    attacks.append({
                        'username': u,
                        'failed_count': r['failed_count'],
                        'last_attempt': str(r['last_attempt']) if r['last_attempt'] else '',
                        'threshold': Config.BRUTEFORCE_THRESHOLD,
                        'is_quarantined': is_quarantined,
                        'group': grp or 'Chưa gán'
                    })
        except Exception as ex:
            logging.error(f"Error in get_live_attacks: {ex}")
        finally:
            if conn:
                conn.close()
        return attacks

detector_instance = ActiveDefenseDetector()
