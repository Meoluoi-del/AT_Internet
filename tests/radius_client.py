import socket
import struct
import hashlib
import hmac
import os

# RADIUS Packet Codes (RFC 2865 / RFC 2866)
ACCESS_REQUEST = 1
ACCESS_ACCEPT = 2
ACCESS_REJECT = 3
ACCOUNTING_REQUEST = 4
ACCOUNTING_RESPONSE = 5

# Common Attribute Types
ATTR_USER_NAME = 1
ATTR_USER_PASSWORD = 2
ATTR_NAS_IP_ADDRESS = 4
ATTR_NAS_PORT = 5
ATTR_FRAMED_IP_ADDRESS = 8
ATTR_REPLY_MESSAGE = 18
ATTR_SESSION_TIMEOUT = 27
ATTR_IDLE_TIMEOUT = 28
ATTR_CALLED_STATION_ID = 30
ATTR_CALLING_STATION_ID = 31
ATTR_ACCT_STATUS_TYPE = 40
ATTR_ACCT_INPUT_OCTETS = 42
ATTR_ACCT_OUTPUT_OCTETS = 43
ATTR_ACCT_SESSION_ID = 44
ATTR_ACCT_SESSION_TIME = 46
ATTR_ACCT_TERMINATE_CAUSE = 49
ATTR_TUNNEL_TYPE = 64
ATTR_TUNNEL_MEDIUM_TYPE = 65
ATTR_TUNNEL_PRIVATE_GROUP_ID = 81
ATTR_MESSAGE_AUTHENTICATOR = 80

# Acct-Status-Type Values
ACCT_STATUS_START = 1
ACCT_STATUS_STOP = 2
ACCT_STATUS_INTERIM_UPDATE = 3

def encode_password(secret: str, authenticator: bytes, password: str) -> bytes:
    """Encode password according to RFC 2865 section 5.2 (MD5 XOR)."""
    pwd_bytes = password.encode('utf-8')
    # Pad to multiple of 16 bytes
    pad_len = 16 - (len(pwd_bytes) % 16)
    if pad_len == 0:
        pad_len = 16
    padded = pwd_bytes + (b'\x00' * pad_len)
    
    result = bytearray()
    last_block = authenticator
    secret_bytes = secret.encode('utf-8')
    
    for i in range(0, len(padded), 16):
        block = padded[i:i+16]
        h = hashlib.md5(secret_bytes + last_block).digest()
        cipher_block = bytes([b ^ k for b, k in zip(block, h)])
        result.extend(cipher_block)
        last_block = cipher_block
        
    return bytes(result)

def build_attribute(attr_type: int, value: bytes) -> bytes:
    """Build TLV (Type-Length-Value) attribute."""
    length = len(value) + 2
    return struct.pack('!BB', attr_type, length) + value

def send_radius_auth(host: str, port: int, secret: str, username: str, password: str, timeout: int = 4):
    """
    Sends RADIUS Access-Request packet and parses the response.
    Returns: dict with 'code', 'code_name', 'vlan', 'attributes'
    """
    packet_id = os.urandom(1)[0]
    authenticator = os.urandom(16)
    
    # Build attributes
    attrs = bytearray()
    attrs.extend(build_attribute(ATTR_USER_NAME, username.encode('utf-8')))
    encrypted_pwd = encode_password(secret, authenticator, password)
    attrs.extend(build_attribute(ATTR_USER_PASSWORD, encrypted_pwd))
    attrs.extend(build_attribute(ATTR_NAS_IP_ADDRESS, socket.inet_aton("127.0.0.1")))
    attrs.extend(build_attribute(ATTR_NAS_PORT, struct.pack('!I', 0)))
    
    # Message-Authenticator (RFC 2869 / RFC 3579 - Chống tấn công BlastRADIUS CVE-2024-3596)
    ma_attr_offset = 20 + len(attrs) + 2  # 20 bytes header, 2 bytes TLV type & len
    attrs.extend(build_attribute(ATTR_MESSAGE_AUTHENTICATOR, b'\x00' * 16))
    
    # Build Header
    total_len = 20 + len(attrs)
    header = struct.pack('!BBH16s', ACCESS_REQUEST, packet_id, total_len, authenticator)
    packet = bytearray(header + bytes(attrs))
    
    # Tính HMAC-MD5 cho toàn bộ packet (với 16 bytes Message-Authenticator là 0)
    secret_bytes = secret.encode('utf-8')
    ma_hash = hmac.new(secret_bytes, packet, hashlib.md5).digest()
    packet[ma_attr_offset:ma_attr_offset + 16] = ma_hash
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    
    try:
        sock.sendto(packet, (host, port))
        resp, _ = sock.recvfrom(4096)
    except socket.timeout:
        return {'code': 0, 'code_name': 'TIMEOUT', 'vlan': None, 'attributes': {}}
    finally:
        sock.close()
        
    if len(resp) < 20:
        return {'code': 0, 'code_name': 'INVALID_RESPONSE', 'vlan': None, 'attributes': {}}
        
    resp_code, resp_id, resp_len, resp_auth = struct.unpack('!BBH16s', resp[:20])
    
    # 1. Kiểm tra tính toàn vẹn Packet Identifier (RFC 2865 Section 3)
    if resp_id != packet_id:
        return {'code': 0, 'code_name': 'PACKET_ID_MISMATCH', 'vlan': None, 'attributes': {}}
        
    # 2. Xác thực Response Authenticator chống giả mạo phản hồi (RFC 2865 Section 3)
    secret_bytes = secret.encode('utf-8')
    expected_auth = hashlib.md5(resp[:4] + authenticator + resp[20:resp_len] + secret_bytes).digest()
    if resp_auth != expected_auth:
        return {'code': 0, 'code_name': 'AUTHENTICATOR_MISMATCH', 'vlan': None, 'attributes': {}}
    
    parsed_attrs = {}
    pos = 20
    vlan_id = None
    
    while pos < resp_len and pos + 2 <= len(resp):
        a_type, a_len = struct.unpack('!BB', resp[pos:pos+2])
        if a_len < 2 or pos + a_len > len(resp):
            break
        a_val = resp[pos+2:pos+a_len]
        
        if a_type == ATTR_TUNNEL_PRIVATE_GROUP_ID:
            # First byte might be tag if tagged tunnel
            try:
                # Remove tag if present
                vlan_str = a_val.decode('utf-8', errors='ignore').lstrip(':\x00\x01\x02\x03\x04\x05\x06\x07\x08\t')
                # If still starts with colon or null, clean
                vlan_id = ''.join([c for c in vlan_str if c.isdigit()])
            except:
                pass
            parsed_attrs['Tunnel-Private-Group-Id'] = vlan_id
        elif a_type == ATTR_TUNNEL_TYPE:
            parsed_attrs['Tunnel-Type'] = 'VLAN'
        elif a_type == ATTR_TUNNEL_MEDIUM_TYPE:
            parsed_attrs['Tunnel-Medium-Type'] = 'IEEE-802'
        elif a_type == ATTR_REPLY_MESSAGE:
            parsed_attrs['Reply-Message'] = a_val.decode('utf-8', errors='ignore')
        elif a_type == ATTR_SESSION_TIMEOUT and len(a_val) == 4:
            parsed_attrs['Session-Timeout'] = struct.unpack('!I', a_val)[0]
        elif a_type == ATTR_IDLE_TIMEOUT and len(a_val) == 4:
            parsed_attrs['Idle-Timeout'] = struct.unpack('!I', a_val)[0]
            
        pos += a_len
        
    code_names = {
        ACCESS_ACCEPT: 'Access-Accept',
        ACCESS_REJECT: 'Access-Reject'
    }
    
    return {
        'code': resp_code,
        'code_name': code_names.get(resp_code, f'UNKNOWN({resp_code})'),
        'vlan': vlan_id,
        'attributes': parsed_attrs
    }

def send_radius_acct(host: str, port: int, secret: str, username: str, session_id: str,
                     status_type: int, framed_ip: str = "192.168.20.101",
                     session_time: int = 0, input_octets: int = 0, output_octets: int = 0,
                     nas_ip: str = "127.0.0.1", calling_station_id: str = "00-11-22-33-44-55",
                     called_station_id: str = "AA-BB-CC-DD-EE-FF:PTIT-NAC",
                     terminate_cause: int = 1, timeout: int = 4):
    """
    Sends RADIUS Accounting-Request packet according to RFC 2866.
    status_type: 1 (Start), 2 (Stop), 3 (Interim-Update)
    Returns: dict with 'success', 'code', 'code_name'
    """
    packet_id = os.urandom(1)[0]
    
    attrs = bytearray()
    attrs.extend(build_attribute(ATTR_USER_NAME, username.encode('utf-8')))
    attrs.extend(build_attribute(ATTR_ACCT_STATUS_TYPE, struct.pack('!I', status_type)))
    attrs.extend(build_attribute(ATTR_ACCT_SESSION_ID, session_id.encode('utf-8')))
    attrs.extend(build_attribute(ATTR_NAS_IP_ADDRESS, socket.inet_aton(nas_ip)))
    attrs.extend(build_attribute(ATTR_NAS_PORT, struct.pack('!I', 0)))
    
    if framed_ip:
        attrs.extend(build_attribute(ATTR_FRAMED_IP_ADDRESS, socket.inet_aton(framed_ip)))
    if calling_station_id:
        attrs.extend(build_attribute(ATTR_CALLING_STATION_ID, calling_station_id.encode('utf-8')))
    if called_station_id:
        attrs.extend(build_attribute(ATTR_CALLED_STATION_ID, called_station_id.encode('utf-8')))
        
    if status_type in (ACCT_STATUS_STOP, ACCT_STATUS_INTERIM_UPDATE):
        attrs.extend(build_attribute(ATTR_ACCT_SESSION_TIME, struct.pack('!I', session_time)))
        attrs.extend(build_attribute(ATTR_ACCT_INPUT_OCTETS, struct.pack('!I', input_octets)))
        attrs.extend(build_attribute(ATTR_ACCT_OUTPUT_OCTETS, struct.pack('!I', output_octets)))
        
    if status_type == ACCT_STATUS_STOP:
        attrs.extend(build_attribute(ATTR_ACCT_TERMINATE_CAUSE, struct.pack('!I', terminate_cause)))
        
    # RFC 2866 Section 3: Request Authenticator = MD5(Code + Id + Length + 16 zero octets + Attrs + Secret)
    total_len = 20 + len(attrs)
    zero_auth = b'\x00' * 16
    hdr_for_hash = struct.pack('!BBH16s', ACCOUNTING_REQUEST, packet_id, total_len, zero_auth)
    secret_bytes = secret.encode('utf-8')
    req_auth = hashlib.md5(hdr_for_hash + attrs + secret_bytes).digest()
    
    packet = struct.pack('!BBH16s', ACCOUNTING_REQUEST, packet_id, total_len, req_auth) + bytes(attrs)
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    
    try:
        sock.sendto(packet, (host, port))
        resp, _ = sock.recvfrom(4096)
    except socket.timeout:
        return {'success': False, 'code': 0, 'code_name': 'TIMEOUT'}
    finally:
        sock.close()
        
    if len(resp) < 20:
        return {'success': False, 'code': 0, 'code_name': 'INVALID_RESPONSE'}
        
    resp_code, resp_id, resp_len, resp_auth = struct.unpack('!BBH16s', resp[:20])
    
    if resp_id != packet_id:
        return {'success': False, 'code': resp_code, 'code_name': 'PACKET_ID_MISMATCH'}
        
    # Verify Response Authenticator: MD5(Code + Id + Length + Request_Auth + Attrs + Secret)
    expected_resp_auth = hashlib.md5(resp[:4] + req_auth + resp[20:resp_len] + secret_bytes).digest()
    if resp_auth != expected_resp_auth:
        return {'success': False, 'code': resp_code, 'code_name': 'AUTHENTICATOR_MISMATCH'}
        
    is_success = (resp_code == ACCOUNTING_RESPONSE)
    return {
        'success': is_success,
        'code': resp_code,
        'code_name': 'Accounting-Response' if is_success else f'UNKNOWN({resp_code})'
    }
