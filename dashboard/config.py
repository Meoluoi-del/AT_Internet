import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'nac-super-secret-key-ptithcm-2026')
    
    # LDAP Configuration
    LDAP_HOST = os.environ.get('LDAP_HOST', 'nac_ldap')
    LDAP_PORT = int(os.environ.get('LDAP_PORT', 389))
    LDAP_BASE_DN = os.environ.get('LDAP_BASE_DN', 'dc=attt,dc=ptit,dc=edu,dc=vn')
    LDAP_BIND_DN = os.environ.get('LDAP_BIND_DN', 'cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn')
    LDAP_BIND_PASSWORD = os.environ.get('LDAP_BIND_PASSWORD', 'AdminPassword123!')
    
    # MySQL / MariaDB Configuration
    DB_HOST = os.environ.get('DB_HOST', 'nac_mariadb')
    DB_PORT = int(os.environ.get('DB_PORT', 3306))
    DB_USER = os.environ.get('DB_USER', 'radius')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', 'RadPassword123!')
    DB_NAME = os.environ.get('DB_NAME', 'radius')
    
    # Active Defense / Brute-force threshold
    BRUTEFORCE_THRESHOLD = int(os.environ.get('BRUTEFORCE_THRESHOLD', 6))  # 6 failed attempts
    BRUTEFORCE_WINDOW_SECONDS = int(os.environ.get('BRUTEFORCE_WINDOW_SECONDS', 180)) # within 3 minutes
