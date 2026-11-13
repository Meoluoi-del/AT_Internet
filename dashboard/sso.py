import time
import json
import base64
import hmac
import hashlib
import secrets

def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')

def _b64url_decode(s: str) -> bytes:
    padding = (4 - len(s) % 4) % 4
    return base64.urlsafe_b64decode(s + '=' * padding)

def create_jwt(payload: dict, secret_key: str, expires_in: int = 3600) -> str:
    """Tạo JSON Web Token (JWT) có chữ ký HMAC-SHA256 chuẩn RFC 7519."""
    header = {"alg": "HS256", "typ": "JWT"}
    now = int(time.time())
    payload_copy = payload.copy()
    payload_copy.setdefault('iat', now)
    payload_copy.setdefault('exp', now + expires_in)
    payload_copy.setdefault('iss', 'https://sso.ptit.edu.vn')
    
    encoded_header = _b64url_encode(json.dumps(header).encode('utf-8'))
    encoded_payload = _b64url_encode(json.dumps(payload_copy).encode('utf-8'))
    signing_input = f"{encoded_header}.{encoded_payload}".encode('ascii')
    signature = hmac.new(secret_key.encode('utf-8'), signing_input, hashlib.sha256).digest()
    return f"{encoded_header}.{encoded_payload}.{_b64url_encode(signature)}"

def verify_jwt(token: str, secret_key: str) -> dict:
    """Xác thực chữ ký và kiểm tra thời hạn JWT."""
    parts = token.split('.')
    if len(parts) != 3:
        raise ValueError("Invalid JWT format")
    encoded_header, encoded_payload, encoded_signature = parts
    signing_input = f"{encoded_header}.{encoded_payload}".encode('ascii')
    expected_sig = hmac.new(secret_key.encode('utf-8'), signing_input, hashlib.sha256).digest()
    if not hmac.compare_digest(_b64url_encode(expected_sig), encoded_signature):
        raise ValueError("Signature mismatch")
    payload = json.loads(_b64url_decode(encoded_payload).decode('utf-8'))
    if payload.get('exp', 0) < time.time():
        raise ValueError("Token expired")
    return payload
