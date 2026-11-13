import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

from radius_client import send_radius_auth

def test_user(username, password, expected_vlan=None):
    print(f"\n[TESTING] Authenticating user: '{username}' with password: '{password}'")
    result = send_radius_auth('127.0.0.1', 1812, 'testing123', username, password)
    
    code_name = result['code_name']
    vlan = result['vlan']
    
    if code_name == 'Access-Accept':
        print(f"  --> Status: \033[92m{code_name}\033[0m")
        print(f"  --> Assigned Dynamic VLAN: \033[96m{vlan}\033[0m (Expected: {expected_vlan})")
        if expected_vlan and str(vlan) == str(expected_vlan):
            print("  --> Result: \033[92m[PASSED - VLAN MATCHES POLICY]\033[0m")
        elif expected_vlan:
            print("  --> Result: \033[93m[WARNING - VLAN DIFFERENT FROM EXPECTED]\033[0m")
    else:
        print(f"  --> Status: \033[91m{code_name}\033[0m")
        if expected_vlan is None:
            print("  --> Result: \033[92m[PASSED - CORRECTLY REJECTED]\033[0m")
            
    return result

if __name__ == '__main__':
    if len(sys.argv) >= 3:
        user = sys.argv[1]
        pwd = sys.argv[2]
        test_user(user, pwd)
    else:
        print("="*65)
        print(" KIỂM THỬ XÁC THỰC AAA & CẤP PHÁT DYNAMIC VLAN (RFC 2868 / 3580)")
        print("="*65)
        test_user('sv_an', 'P@ssword123!', expected_vlan='20')
        test_user('gv_nguyen', 'P@ssword123!', expected_vlan='30')
        test_user('admin01', 'P@ssword123!', expected_vlan='10')
        test_user('sv_an', 'SaiMatKhau999', expected_vlan=None)
