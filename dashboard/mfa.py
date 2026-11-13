import os
import time
import hmac
import hashlib
import struct
import base64
import urllib.parse

def generate_secret() -> str:
    """Tạo khóa bí mật ngẫu nhiên Base32 chuẩn RFC 4648 (160-bit)."""
    return base64.b32encode(os.urandom(20)).decode('ascii').replace('=', '')

def get_totp_code(secret_b32: str, for_time: float = None, interval: int = 30, digits: int = 6) -> str:
    """Sinh mã xác thực TOTP 6 chữ số theo chuẩn RFC 6238."""
    if for_time is None:
        for_time = time.time()
    secret_clean = secret_b32.strip().replace(' ', '').upper()
    padding = (8 - len(secret_clean) % 8) % 8
    key = base64.b32decode(secret_clean + '=' * padding, casefold=True)
    counter = int(for_time // interval)
    msg = struct.pack(">Q", counter)
    digest = hmac.new(key, msg, hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    binary = (struct.unpack(">I", digest[offset:offset+4])[0] & 0x7FFFFFFF) % (10 ** digits)
    return f"{binary:0{digits}d}"

def verify_totp(secret_b32: str, code: str, window: int = 1, interval: int = 30) -> bool:
    """Kiểm tra mã TOTP trong cửa sổ dung sai (+/- 30 giây) chống lệch đồng hồ."""
    if not code or len(code.strip()) != 6:
        return False
    code = code.strip()
    now = time.time()
    for step in range(-window, window + 1):
        target_time = now + (step * interval)
        try:
            expected_code = get_totp_code(secret_b32, target_time, interval)
            if hmac.compare_digest(expected_code, code):
                return True
        except Exception:
            continue
    return False

def get_totp_uri(secret_b32: str, username: str, issuer: str = "PTITHCM NAC") -> str:
    """Tạo chuỗi URI chuẩn otpauth:// quét bằng Google/Microsoft Authenticator."""
    label = f"{issuer}:{username}"
    params = {
        'secret': secret_b32.strip().replace(' ', '').upper(),
        'issuer': issuer,
        'algorithm': 'SHA1',
        'digits': '6',
        'period': '30'
    }
    return f"otpauth://totp/{urllib.parse.quote(label)}?{urllib.parse.urlencode(params)}"
