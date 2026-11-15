import os
import sys
import pymysql

# Thêm đường dẫn dashboard để import sso
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'dashboard'))
from sso import hash_client_secret

conn = pymysql.connect(
    host='127.0.0.1',
    user='root',
    password='RootPassword123!',
    database='radius',
    cursorclass=pymysql.cursors.DictCursor
)

clients_to_update = [
    {
        'client_id': 'qldt_lms',
        'secret': 'sec_qldt_9921',
        'redirect_uri': 'http://localhost:5000/sso/callback,http://qldt.ptit.edu.vn/sso/callback'
    },
    {
        'client_id': 'elibrary',
        'secret': 'sec_lib_8832',
        'redirect_uri': 'http://localhost:5000/sso/callback,http://lib.ptit.edu.vn/sso/callback'
    },
    {
        'client_id': 'vpn_portal',
        'secret': 'sec_vpn_7743',
        'redirect_uri': 'http://localhost:5000/sso/callback,http://vpn.ptit.edu.vn/sso/callback'
    },
    {
        'client_id': 'webmail',
        'secret': 'sec_mail_6654',
        'redirect_uri': 'http://localhost:5000/sso/callback,http://mail.ptit.edu.vn/sso/callback'
    },
    {
        'client_id': 'nac_admin',
        'secret': 'sec_nac_5565',
        'redirect_uri': 'http://localhost:5000/sso/callback'
    }
]

with conn.cursor() as cursor:
    for c in clients_to_update:
        hashed = hash_client_secret(c['secret'])
        cursor.execute("""
            UPDATE sso_clients 
            SET client_secret = %s, redirect_uri = %s 
            WHERE client_id = %s
        """, (hashed, c['redirect_uri'], c['client_id']))
        print(f"Updated client {c['client_id']}: secret hashed with PBKDF2, redirect_uris: {c['redirect_uri']}")
    conn.commit()

conn.close()
print("SSO clients migration completed successfully.")
