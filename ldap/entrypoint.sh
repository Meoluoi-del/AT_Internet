#!/bin/bash
set -e

# First time initialization
if [ ! -f /var/lib/ldap/INITIALIZED_FLAG ]; then
    echo "[*] Starting temporary slapd for bootstrap import..."
    slapd -h "ldap://127.0.0.1:389/ ldapi:///" -u openldap -g openldap
    sleep 2

    echo "[*] Setting olcRootPW..."
    ldapmodify -Y EXTERNAL -H ldapi:/// << 'EOF' || true
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: AdminPassword123!
EOF

    echo "[*] Importing custom entries from init-ldap.ldif..."
    ldapadd -x -D "cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn" -w "AdminPassword123!" -f /etc/ldap/init-ldap.ldif || true

    echo "[*] Shutting down temporary slapd..."
    pkill slapd || true
    sleep 1
    touch /var/lib/ldap/INITIALIZED_FLAG
fi

echo "[+] Starting production slapd on port 389..."
exec slapd -h "ldap://0.0.0.0:389/ ldapi:///" -u openldap -g openldap -d 256
