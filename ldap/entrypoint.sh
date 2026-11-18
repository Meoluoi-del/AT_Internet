#!/bin/bash
set -e

# First time initialization
if [ ! -f /var/lib/ldap/INITIALIZED_FLAG ]; then
    echo "[*] Starting temporary slapd for bootstrap import..."
    slapd -h "ldap://127.0.0.1:389/ ldapi:///" -u openldap -g openldap
    sleep 2

    echo "[*] Setting olcRootPW (SSHA Hashed) and ACLs..."
    ROOT_PW_HASH=$(slappasswd -s "AdminPassword123!")
    ldapmodify -Y EXTERNAL -H ldapi:/// << EOF || true
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: ${ROOT_PW_HASH}
-
replace: olcAccess
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external manage by * break
olcAccess: {1}to attrs=userPassword by dn.exact="cn=radius-svc,ou=services,dc=attt,dc=ptit,dc=edu,dc=vn" read by dn.exact="cn=dashboard-svc,ou=services,dc=attt,dc=ptit,dc=edu,dc=vn" write by self write by anonymous auth by * none
olcAccess: {2}to dn.subtree="ou=users,dc=attt,dc=ptit,dc=edu,dc=vn" by dn.exact="cn=dashboard-svc,ou=services,dc=attt,dc=ptit,dc=edu,dc=vn" write by * read
olcAccess: {3}to dn.subtree="ou=groups,dc=attt,dc=ptit,dc=edu,dc=vn" by dn.exact="cn=dashboard-svc,ou=services,dc=attt,dc=ptit,dc=edu,dc=vn" write by * read
olcAccess: {4}to attrs=shadowLastChange by self write by * read
olcAccess: {5}to * by * read
EOF

    echo "[*] Importing custom entries from init-ldap.ldif..."
    ldapadd -x -c -D "cn=admin,dc=attt,dc=ptit,dc=edu,dc=vn" -w "AdminPassword123!" -f /etc/ldap/init-ldap.ldif || true

    echo "[*] Shutting down temporary slapd..."
    pkill slapd || true
    sleep 1
    touch /var/lib/ldap/INITIALIZED_FLAG
fi

echo "[+] Starting production slapd on port 389..."
exec slapd -h "ldap://0.0.0.0:389/ ldapi:///" -u openldap -g openldap -d 256
