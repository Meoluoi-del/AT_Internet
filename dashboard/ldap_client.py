import os
import hashlib
import base64
import logging
from ldap3 import Server, Connection, ALL, SUBTREE, BASE, MODIFY_REPLACE, MODIFY_ADD, MODIFY_DELETE
from config import Config

def ssha_hash(password: str) -> str:
    """Generate standard OpenLDAP SSHA password hash with 4-byte random salt."""
    salt = os.urandom(4)
    h = hashlib.sha1(password.encode('utf-8') + salt).digest()
    return '{SSHA}' + base64.b64encode(h + salt).decode('ascii')

class LDAPClient:
    def __init__(self):
        self.server = Server(Config.LDAP_HOST, port=Config.LDAP_PORT, get_info=ALL)
        self.base_dn = Config.LDAP_BASE_DN
        self.users_dn = f"ou=users,{self.base_dn}"
        self.groups_dn = f"ou=groups,{self.base_dn}"
        
    def _get_connection(self):
        conn = Connection(
            self.server,
            user=Config.LDAP_BIND_DN,
            password=Config.LDAP_BIND_PASSWORD,
            auto_bind=True
        )
        return conn

    def get_all_users(self):
        """Retrieve all users with their group memberships and VLAN status."""
        conn = self._get_connection()
        try:
            # 1. Search all users
            conn.search(
                search_base=self.users_dn,
                search_filter='(objectClass=inetOrgPerson)',
                search_scope=SUBTREE,
                attributes=['uid', 'cn', 'sn', 'mail', 'description']
            )
            users_map = {}
            for entry in conn.entries:
                uid = str(entry.uid)
                users_map[uid] = {
                    'uid': uid,
                    'cn': str(entry.cn) if entry.cn else '',
                    'mail': str(entry.mail) if entry.mail else '',
                    'description': str(entry.description) if entry.description else '',
                    'group': 'Chưa gán',
                    'vlan': '99',
                    'status': 'active'
                }
            
            # 2. Search groups to find memberships
            conn.search(
                search_base=self.groups_dn,
                search_filter='(objectClass=groupOfNames)',
                search_scope=SUBTREE,
                attributes=['cn', 'member']
            )
            for g_entry in conn.entries:
                g_name = str(g_entry.cn)
                members = [str(m) for m in g_entry.member.values] if g_entry.member else []
                for m_dn in members:
                    # extract uid from DN (e.g., uid=sv_an,ou=users,...)
                    parts = [p.strip() for p in m_dn.split(',')]
                    for p in parts:
                        if p.lower().startswith('uid='):
                            uid = p.split('=', 1)[1]
                            if uid in users_map:
                                users_map[uid]['group'] = g_name
                                if g_name == 'quantri':
                                    users_map[uid]['vlan'] = '10'
                                elif g_name == 'sinhvien':
                                    users_map[uid]['vlan'] = '20'
                                elif g_name == 'giangvien':
                                    users_map[uid]['vlan'] = '30'
                                elif g_name == 'quarantine':
                                    users_map[uid]['vlan'] = '99'
                                    users_map[uid]['status'] = 'quarantined'
                                    
            return list(users_map.values())
        finally:
            conn.unbind()

    def authenticate(self, uid: str, password: str) -> bool:
        """
        Xác thực tài khoản người dùng qua OpenLDAP bằng cơ chế Direct Bind.
        Hỗ trợ toàn bộ tài khoản Sinh viên, Giảng viên trong hệ thống IAM trường.
        """
        if not uid or not password:
            return False
        user_dn = f"uid={uid},{self.users_dn}"
        try:
            user_conn = Connection(self.server, user=user_dn, password=password)
            if user_conn.bind():
                user_conn.unbind()
                return True
            return False
        except Exception:
            return False

    def get_user_info(self, uid: str) -> dict:
        """Lấy thông tin hồ sơ chi tiết của người dùng từ OpenLDAP (cn, mail, group, vlan, status)."""
        conn = self._get_connection()
        try:
            conn.search(
                search_base=self.users_dn,
                search_filter=f'(uid={uid})',
                search_scope=SUBTREE,
                attributes=['uid', 'cn', 'sn', 'mail', 'description']
            )
            if not conn.entries:
                return None
            entry = conn.entries[0]
            group = self.get_user_group(uid) or 'sinhvien'
            vlan_map = {'quantri': '10', 'sinhvien': '20', 'giangvien': '30', 'quarantine': '99'}
            return {
                'uid': uid,
                'cn': str(entry.cn) if entry.cn else uid,
                'mail': str(entry.mail) if entry.mail else f"{uid}@ptit.edu.vn",
                'group': group,
                'vlan': vlan_map.get(group, '20'),
                'status': 'quarantined' if group == 'quarantine' else 'active'
            }
        finally:
            conn.unbind()

    def user_exists(self, uid: str) -> bool:
        """Kiểm tra tài khoản có thực sự tồn tại trong cây thư mục OpenLDAP hay không."""
        conn = self._get_connection()
        try:
            conn.search(
                search_base=self.users_dn,
                search_filter=f'(uid={uid})',
                search_scope=SUBTREE,
                attributes=['uid']
            )
            return len(conn.entries) > 0
        finally:
            conn.unbind()

    def get_user_group(self, uid: str):
        conn = self._get_connection()
        try:
            user_dn = f"uid={uid},{self.users_dn}"
            conn.search(
                search_base=self.groups_dn,
                search_filter=f'(&(objectClass=groupOfNames)(member={user_dn}))',
                search_scope=SUBTREE,
                attributes=['cn']
            )
            if conn.entries:
                return str(conn.entries[0].cn)
            return None
        finally:
            conn.unbind()

    def create_user(self, uid: str, cn: str, sn: str, mail: str, password: str, group_name: str, desc: str = ""):
        conn = self._get_connection()
        try:
            user_dn = f"uid={uid},{self.users_dn}"
            password_ssha = ssha_hash(password)
            
            # 1. Add inetOrgPerson object
            attrs = {
                'objectClass': ['top', 'person', 'organizationalPerson', 'inetOrgPerson'],
                'uid': uid,
                'cn': cn,
                'sn': sn or cn.split()[-1] if cn.split() else 'User',
                'mail': mail,
                'userPassword': password_ssha,
                'description': desc or f"User {cn} - Group {group_name}"
            }
            conn.add(user_dn, attributes=attrs)
            if conn.result.get('result') != 0:
                raise Exception(f"Failed to create LDAP user: {conn.result.get('description')}")
            
            # 2. Add user DN to the specified group
            group_dn = f"cn={group_name},{self.groups_dn}"
            conn.modify(group_dn, {'member': [(MODIFY_ADD, [user_dn])]})
            if conn.result.get('result') not in (0, 68):
                # Rollback user entry on failure
                conn.delete(user_dn)
                raise Exception(f"Failed to add user to group {group_name}: {conn.result.get('description')}")
            return True
        finally:
            conn.unbind()

    def delete_user(self, uid: str):
        conn = self._get_connection()
        try:
            user_dn = f"uid={uid},{self.users_dn}"
            # 1. Remove from all groups
            conn.search(
                search_base=self.groups_dn,
                search_filter=f'(&(objectClass=groupOfNames)(member={user_dn}))',
                search_scope=SUBTREE,
                attributes=['cn']
            )
            for g_entry in conn.entries:
                g_dn = g_entry.entry_dn
                conn.modify(g_dn, {'member': [(MODIFY_DELETE, [user_dn])]})
                
            # 2. Delete user entry
            conn.delete(user_dn)
            return conn.result.get('result') in (0, 32)
        finally:
            conn.unbind()

    def change_user_group(self, uid: str, new_group: str) -> bool:
        """
        Chuyển nhóm người dùng trên OpenLDAP có kiểm tra kết quả chặt chẽ.
        Đảm bảo không nuốt lỗi, thêm vào nhóm đích trước khi gỡ khỏi nhóm cũ.
        """
        conn = self._get_connection()
        try:
            user_dn = f"uid={uid},{self.users_dn}"
            target_group_dn = f"cn={new_group},{self.groups_dn}"

            # 1. Kiểm tra nhóm đích có tồn tại trong OpenLDAP không
            conn.search(
                search_base=target_group_dn,
                search_filter='(objectClass=groupOfNames)',
                search_scope=BASE,
                attributes=['cn']
            )
            if not conn.entries:
                logging.error(f"[LDAP] Nhóm đích '{new_group}' không tồn tại trong DIT.")
                return False

            # 2. Thêm người dùng vào nhóm đích trước (result 0 = success, 68 = already member)
            conn.modify(target_group_dn, {'member': [(MODIFY_ADD, [user_dn])]})
            if conn.result.get('result') not in (0, 68):
                logging.error(f"[LDAP] Không thể thêm {uid} vào nhóm {new_group}: {conn.result.get('description')}")
                return False

            # 3. Gỡ người dùng khỏi các nhóm khác
            conn.search(
                search_base=self.groups_dn,
                search_filter=f'(&(objectClass=groupOfNames)(member={user_dn}))',
                search_scope=SUBTREE,
                attributes=['cn']
            )
            for g_entry in conn.entries:
                g_dn = g_entry.entry_dn
                if g_dn.lower() != target_group_dn.lower():
                    conn.modify(g_dn, {'member': [(MODIFY_DELETE, [user_dn])]})
                    if conn.result.get('result') not in (0, 16):
                        logging.warning(f"[LDAP] Cảnh báo: Không thể gỡ {uid} khỏi {g_dn}: {conn.result.get('description')}")

            return True
        except Exception as e:
            logging.error(f"[LDAP] Lỗi nghiêm trọng khi chuyển nhóm cho {uid} sang {new_group}: {e}")
            return False
        finally:
            conn.unbind()

    def quarantine_user(self, uid: str):
        """Move user to quarantine group (VLAN 99)."""
        return self.change_user_group(uid, 'quarantine')

    def unquarantine_user(self, uid: str, target_group: str = 'sinhvien'):
        """Restore user from quarantine back to operational group."""
        return self.change_user_group(uid, target_group)

    def get_user_by_email_or_uid(self, identifier: str) -> dict:
        """Tra cứu thông tin người dùng từ OpenLDAP bằng username (uid) hoặc email."""
        if not identifier or not isinstance(identifier, str):
            return None
        identifier = identifier.strip()
        conn = self._get_connection()
        try:
            safe_id = identifier.replace('*', '').replace('(', '').replace(')', '').replace('\\', '')
            conn.search(
                search_base=self.users_dn,
                search_filter=f'(|(uid={safe_id})(mail={safe_id}))',
                search_scope=SUBTREE,
                attributes=['uid', 'cn', 'sn', 'mail', 'description']
            )
            if not conn.entries:
                return None
            entry = conn.entries[0]
            uid = str(entry.uid)
            group = self.get_user_group(uid) or 'sinhvien'
            return {
                'uid': uid,
                'cn': str(entry.cn) if entry.cn else uid,
                'mail': str(entry.mail) if entry.mail else f"{uid}@ptit.edu.vn",
                'group': group
            }
        finally:
            conn.unbind()

    def reset_user_password(self, uid: str, new_password: str) -> bool:
        """
        Đặt lại mật khẩu cho tài khoản người dùng trên OpenLDAP.
        Tự động băm SSHA với muối ngẫu nhiên (RFC-compliant salted SHA-1).
        """
        if not uid or not new_password:
            return False
        conn = self._get_connection()
        try:
            user_dn = f"uid={uid},{self.users_dn}"
            password_ssha = ssha_hash(new_password)
            conn.modify(user_dn, {'userPassword': [(MODIFY_REPLACE, [password_ssha])]})
            return conn.result.get('result') == 0
        except Exception as e:
            logging.error(f"[LDAP] Lỗi khi đổi mật khẩu cho {uid}: {e}")
            return False
        finally:
            conn.unbind()
