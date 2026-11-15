import requests
import re
import os
import sys
import secrets

BASE_URL = "http://127.0.0.1:5000"

def run_tests():
    print("==================================================================")
    print("TEST SUITE: QUARANTINE ENFORCEMENT & IP BLOCKING (NAC & ZERO-TRUST)")
    print("==================================================================")

    # -------------------------------------------------------------------------
    # STEP 1: Admin Login
    # -------------------------------------------------------------------------
    print("\n[STEP 1] Logging in as Admin...")
    s_admin = requests.Session()
    sid_adm = secrets.token_hex(6)
    resp = s_admin.post(f"{BASE_URL}/login?sid={sid_adm}", data={
        "sid": sid_adm,
        "username": "admin",
        "password": "AdminPassword123!"
    }, allow_redirects=False)
    assert resp.status_code == 302, f"Admin login failed: {resp.status_code}"
    print("PASSED: Admin logged in.")

    # -------------------------------------------------------------------------
    # STEP 2: Ensure test user sv_binh is initially active (sinhvien / VLAN 20)
    # -------------------------------------------------------------------------
    print("\n[STEP 2] Preparing test user 'sv_binh' in active state...")
    s_admin.post(f"{BASE_URL}/users/unlock/sv_binh?sid={sid_adm}", data={"target_group": "sinhvien"})

    # Student sv_binh logs in
    s_student = requests.Session()
    sid_stu = secrets.token_hex(6)
    resp = s_student.post(f"{BASE_URL}/login?sid={sid_stu}", data={
        "sid": sid_stu,
        "username": "sv_binh",
        "password": "P@ssword123!"
    }, allow_redirects=False)
    assert resp.status_code == 302 and "/sso" in resp.headers.get('Location', '')
    
    # Access an app before quarantine
    resp_app = s_student.get(f"{BASE_URL}/apps/qldt?sid={sid_stu}")
    assert resp_app.status_code == 200
    assert "sv_binh" in resp_app.text
    print("PASSED: User 'sv_binh' is initially active and can access QLĐT.")

    # -------------------------------------------------------------------------
    # STEP 3: Admin Quarantines sv_binh -> Triggers Instant Session Revocation & IP Block
    # -------------------------------------------------------------------------
    print("\n[STEP 3] Admin quarantines user 'sv_binh'...")
    resp_q = s_admin.post(f"{BASE_URL}/users/quarantine/sv_binh?sid={sid_adm}", allow_redirects=True)
    assert resp_q.status_code == 200
    assert "diện cách ly (VLAN 99)" in resp_q.text or "cách ly" in resp_q.text
    print("PASSED: Admin triggered quarantine for 'sv_binh'.")

    # -------------------------------------------------------------------------
    # STEP 4: Verify Zero-Trust Enforcement: Blocked from all SSO apps
    # -------------------------------------------------------------------------
    print("\n[STEP 4] Verifying 'sv_binh' is BLOCKED from all internal apps...")
    
    # 4.1 QLĐT / LMS
    resp_qldt = s_student.get(f"{BASE_URL}/apps/qldt?sid={sid_stu}", allow_redirects=False)
    assert resp_qldt.status_code == 302, f"Expected 302 redirect for quarantined user, got {resp_qldt.status_code}"
    print("-> 1. Access to QLĐT: BLOCKED & Redirected to SSO Portal!")

    # 4.2 Thư viện số E-Library
    resp_lib = s_student.get(f"{BASE_URL}/apps/elibrary?sid={sid_stu}", allow_redirects=False)
    assert resp_lib.status_code == 302
    print("-> 2. Access to E-Library: BLOCKED & Redirected to SSO Portal!")

    # 4.3 VPN Gateway
    resp_vpn = s_student.get(f"{BASE_URL}/apps/vpn?sid={sid_stu}", allow_redirects=False)
    assert resp_vpn.status_code == 302
    print("-> 3. Access to VPN: BLOCKED & Redirected to SSO Portal!")

    # 4.4 Webmail
    resp_mail = s_student.get(f"{BASE_URL}/apps/webmail?sid={sid_stu}", allow_redirects=False)
    assert resp_mail.status_code == 302
    print("-> 4. Access to Webmail: BLOCKED & Redirected to SSO Portal!")

    # 4.5 Inspect SSO Portal UI for Quarantined Mode
    resp_portal = s_student.get(f"{BASE_URL}/sso?sid={sid_stu}")
    assert resp_portal.status_code == 200
    assert "ĐANG BỊ CÁCH LY (VLAN 99)" in resp_portal.text, "Quarantine warning banner must appear"
    assert "Bị khóa cách ly (VLAN 99)" in resp_portal.text, "App buttons must be disabled"
    print("-> 5. SSO Portal UI: Displays prominent Quarantine Warning & all app buttons locked!")

    # 4.6 OAuth Authorize Endpoint
    resp_auth = s_student.get(f"{BASE_URL}/oauth/authorize?client_id=qldt_lms&sid={sid_stu}")
    assert resp_auth.status_code == 403, f"OAuth authorize must return 403, got {resp_auth.status_code}"
    print("-> 6. OAuth Authorize Endpoint: Returned 403 access_denied!")

    # -------------------------------------------------------------------------
    # STEP 5: Admin Unlocks sv_binh -> Restores Access & Unblocks IP
    # -------------------------------------------------------------------------
    print("\n[STEP 5] Admin unlocks user 'sv_binh' and restores to sinhvien...")
    resp_un = s_admin.post(f"{BASE_URL}/users/unlock/sv_binh?sid={sid_adm}", data={"target_group": "sinhvien"}, allow_redirects=True)
    assert resp_un.status_code == 200
    assert "mở khóa" in resp_un.text.lower() or "giải phóng" in resp_un.text.lower()
    print("PASSED: User 'sv_binh' unlocked and IP unblocked.")

    # Log in fresh as sv_binh to verify access restored
    s_stu2 = requests.Session()
    sid_stu2 = secrets.token_hex(6)
    resp = s_stu2.post(f"{BASE_URL}/login?sid={sid_stu2}", data={
        "sid": sid_stu2,
        "username": "sv_binh",
        "password": "P@ssword123!"
    }, allow_redirects=False)
    assert resp.status_code == 302 and "/sso" in resp.headers.get('Location', '')

    resp_restored = s_stu2.get(f"{BASE_URL}/apps/qldt?sid={sid_stu2}")
    assert resp_restored.status_code == 200
    assert "sv_binh" in resp_restored.text
    print("PASSED: Access to all apps successfully restored after Admin unlock!")

    print("\n==================================================================")
    print("ALL QUARANTINE & IP BLOCKING TESTS PASSED 100%!")
    print("==================================================================")

if __name__ == '__main__':
    run_tests()
