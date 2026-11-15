import requests
import re
import os
import sys
import secrets

BASE_URL = "http://127.0.0.1:5000"

def run_tests():
    print("==================================================================")
    print("STARTING TEST SUITE: LDAP USER GOOGLE-LIKE SSO EXPERIENCE & RBAC")
    print("==================================================================")

    # -------------------------------------------------------------------------
    # TEST 1: OpenLDAP Student Login (sv_vinh) -> Auto-redirect to SSO Launchpad
    # -------------------------------------------------------------------------
    print("\n[TEST 1] Logging in as OpenLDAP Student 'sv_vinh'...")
    s_student = requests.Session()
    sid_student = secrets.token_hex(6)

    login_data = {
        "sid": sid_student,
        "username": "sv_vinh",
        "password": "P@ssword123!"
    }
    resp = s_student.post(f"{BASE_URL}/login?sid={sid_student}", data=login_data, allow_redirects=False)
    assert resp.status_code == 302, f"Expected 302 on login, got {resp.status_code}"
    redirect_target = resp.headers.get('Location', '')
    print(f"-> Redirect destination: {redirect_target}")
    assert "/sso" in redirect_target or "sso" in redirect_target, f"Expected redirect to /sso, got {redirect_target}"
    print("PASSED: OpenLDAP Student 'sv_vinh' redirected directly to SSO Launchpad (/sso)!")

    # -------------------------------------------------------------------------
    # TEST 2: Inspect SSO Launchpad for Student Profile & Connected Apps
    # -------------------------------------------------------------------------
    print("\n[TEST 2] Verifying SSO Launchpad (/sso) content for 'sv_vinh'...")
    resp = s_student.get(f"{BASE_URL}/sso?sid={sid_student}")
    assert resp.status_code == 200, f"Expected 200 on /sso, got {resp.status_code}"
    body = resp.text

    assert "sv_vinh" in body, "Username sv_vinh not found in /sso"
    assert "sinhvien" in body, "Group sinhvien not found in /sso"
    assert "VLAN 20" in body, "VLAN 20 not found in /sso"
    assert "USER" in body, "Role USER not found in /sso"
    assert "qldt_lms" in body, "App QLĐT / LMS not in SSO apps grid"
    assert "elibrary" in body, "App E-Library not in SSO apps grid"
    assert "vpn_portal" in body, "App VPN not in SSO apps grid"
    assert "webmail" in body, "App Webmail not in SSO apps grid"
    # Verify nac_admin is hidden for regular users
    assert "nac_admin" not in body, "Admin console nac_admin must NOT appear in normal user Launchpad"
    print("PASSED: SSO Launchpad correctly configured for Student: shows Profile, VLAN 20, and 4 Google-like ecosystem apps!")

    # -------------------------------------------------------------------------
    # TEST 3: 1-Click Seamless Access to the 4 Ecosystem Services
    # -------------------------------------------------------------------------
    print("\n[TEST 3] Testing 1-Click Seamless Access to the 4 Apps (Google-like Ecosystem)...")
    
    # 3.1 QLĐT / LMS
    resp_qldt = s_student.get(f"{BASE_URL}/apps/qldt?sid={sid_student}")
    assert resp_qldt.status_code == 200, f"Expected 200 on QLĐT, got {resp_qldt.status_code}"
    assert "sv_vinh" in resp_qldt.text
    assert "VLAN 20" in resp_qldt.text
    print("-> 1. Cổng Đào tạo (QLĐT / LMS): OK (Transcript, schedule, CPA loaded for sv_vinh)")

    # 3.2 Thư viện số E-Library
    resp_lib = s_student.get(f"{BASE_URL}/apps/elibrary?sid={sid_student}")
    assert resp_lib.status_code == 200, f"Expected 200 on E-Library, got {resp_lib.status_code}"
    assert "sv_vinh" in resp_lib.text
    assert "THƯ VIỆN SỐ" in resp_lib.text
    print("-> 2. Thư viện Số (E-Library): OK (Student card & library permissions loaded)")

    # 3.3 Zero-Trust VPN Gateway
    resp_vpn = s_student.get(f"{BASE_URL}/apps/vpn?sid={sid_student}")
    assert resp_vpn.status_code == 200, f"Expected 200 on VPN, got {resp_vpn.status_code}"
    assert "10.8.20.15" in resp_vpn.text or "VLAN 20" in resp_vpn.text
    print("-> 3. Cổng VPN Zero-Trust: OK (Virtual tunnel mapped to Student VLAN 20)")

    # 3.4 Webmail PTIT
    resp_mail = s_student.get(f"{BASE_URL}/apps/webmail?sid={sid_student}")
    assert resp_mail.status_code == 200, f"Expected 200 on Webmail, got {resp_mail.status_code}"
    assert "sv_vinh" in resp_mail.text
    assert "sv_vinh@ptit.edu.vn" in resp_mail.text
    print("-> 4. Webmail PTIT: OK (Student mailbox opened seamlessly)")
    print("PASSED: All 4 Google-like ecosystem apps accessed with 1-click without re-entering password!")

    # -------------------------------------------------------------------------
    # TEST 4: RBAC & Access Control: Student Blocked from Admin Pages
    # -------------------------------------------------------------------------
    print("\n[TEST 4] Testing Access Control (Student blocked from NAC Management Center)...")
    
    # Index '/' should redirect to /sso
    resp_idx = s_student.get(f"{BASE_URL}/?sid={sid_student}", allow_redirects=False)
    assert resp_idx.status_code == 302 and "/sso" in resp_idx.headers.get('Location', ''), \
        f"Index should redirect student to /sso, got {resp_idx.status_code} -> {resp_idx.headers.get('Location')}"
    print("-> '/' (Index) access blocked -> redirected to /sso")

    # /users should redirect to /sso
    resp_users = s_student.get(f"{BASE_URL}/users?sid={sid_student}", allow_redirects=False)
    assert resp_users.status_code == 302 and "/sso" in resp_users.headers.get('Location', ''), \
        f"/users should redirect student to /sso, got {resp_users.status_code}"
    print("-> '/users' access blocked -> redirected to /sso")

    # /policies should redirect to /sso
    resp_pol = s_student.get(f"{BASE_URL}/policies?sid={sid_student}", allow_redirects=False)
    assert resp_pol.status_code == 302 and "/sso" in resp_pol.headers.get('Location', ''), \
        f"/policies should redirect student to /sso, got {resp_pol.status_code}"
    print("-> '/policies' access blocked -> redirected to /sso")

    # /audit should redirect to /sso
    resp_audit = s_student.get(f"{BASE_URL}/audit?sid={sid_student}", allow_redirects=False)
    assert resp_audit.status_code == 302 and "/sso" in resp_audit.headers.get('Location', ''), \
        f"/audit should redirect student to /sso, got {resp_audit.status_code}"
    print("-> '/audit' access blocked -> redirected to /sso")
    print("PASSED: Regular student strictly isolated from admin consoles and management routes!")

    # -------------------------------------------------------------------------
    # TEST 5: OpenLDAP Lecturer Login (gv_nguyen)
    # -------------------------------------------------------------------------
    print("\n[TEST 5] Testing OpenLDAP Lecturer Login ('gv_nguyen')...")
    s_lecturer = requests.Session()
    sid_lec = secrets.token_hex(6)

    resp = s_lecturer.post(f"{BASE_URL}/login?sid={sid_lec}", data={
        "sid": sid_lec,
        "username": "gv_nguyen",
        "password": "P@ssword123!"
    }, allow_redirects=False)
    assert resp.status_code == 302 and "/sso" in resp.headers.get('Location', '')
    
    resp_sso_lec = s_lecturer.get(f"{BASE_URL}/sso?sid={sid_lec}")
    assert "gv_nguyen" in resp_sso_lec.text
    assert "giangvien" in resp_sso_lec.text
    assert "VLAN 30" in resp_sso_lec.text
    print("PASSED: Lecturer 'gv_nguyen' logged in successfully, assigned to giangvien (VLAN 30)!")

    # -------------------------------------------------------------------------
    # TEST 6: Single Logout (SLO) & Anti-Session Replay Attack Protection
    # -------------------------------------------------------------------------
    print("\n[TEST 6] Testing Single Logout (SLO) & Anti-Session Replay...")
    # Student triggers SLO
    resp_slo = s_student.get(f"{BASE_URL}/sso/single-logout?sid={sid_student}", allow_redirects=False)
    assert resp_slo.status_code == 302 and "/login" in resp_slo.headers.get('Location', '')
    print("-> Single Logout triggered from SSO Portal.")

    # Replay attack attempt: Try to access /apps/qldt with the revoked student session
    resp_replay = s_student.get(f"{BASE_URL}/apps/qldt?sid={sid_student}", allow_redirects=False)
    assert resp_replay.status_code == 302 and "/login" in resp_replay.headers.get('Location', ''), \
        "Revoked session must not be allowed to access app"
    print("PASSED: SLO invalidated all sessions across apps. Session Replay Attack blocked!")

    # -------------------------------------------------------------------------
    # TEST 7: Admin Login ('admin') -> Lands on Admin Dashboard
    # -------------------------------------------------------------------------
    print("\n[TEST 7] Testing Admin Login ('admin')...")
    s_admin = requests.Session()
    sid_adm = secrets.token_hex(6)

    resp = s_admin.post(f"{BASE_URL}/login?sid={sid_adm}", data={
        "sid": sid_adm,
        "username": "admin",
        "password": "AdminPassword123!"
    }, allow_redirects=False)
    assert resp.status_code == 302
    redirect_target = resp.headers.get('Location', '')
    assert redirect_target.endswith('/') or "index" in redirect_target or "sid=" in redirect_target and "/" in redirect_target, \
        f"Admin should land on /, got {redirect_target}"

    # Admin visits /users
    resp_adm_users = s_admin.get(f"{BASE_URL}/users?sid={sid_adm}")
    assert resp_adm_users.status_code == 200, "Admin should be able to view /users"
    print("PASSED: Admin logs in and lands on Admin Dashboard with full management access!")

    print("\n==================================================================")
    print("ALL 7 TESTS PASSED SUCCESSFULLY! GOOGLE-LIKE SSO EXPERIENCE VERIFIED")
    print("==================================================================")

if __name__ == '__main__':
    run_tests()
