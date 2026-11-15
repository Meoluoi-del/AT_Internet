import os
import time
import json
import base64
import hmac
import hashlib
import secrets
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization

KEYS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'keys')
PRIVATE_KEY_PATH = os.path.join(KEYS_DIR, 'jwt_rsa_private.pem')
PUBLIC_KEY_PATH = os.path.join(KEYS_DIR, 'jwt_rsa_public.pem')
KEY_ID = "nac-sso-key-2026"

_private_key = None
_public_key = None

def _b64url_encode(data: bytes) -> str:
    """Mã hóa base64url không có padding theo chuẩn RFC 7515."""
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')

def _b64url_decode(s: str) -> bytes:
    """Giải mã base64url có bổ sung padding tự động."""
    padding_len = (4 - len(s) % 4) % 4
    return base64.urlsafe_b64decode(s + '=' * padding_len)

def _int_to_b64url(val: int) -> str:
    """Chuyển đổi số nguyên lớn sang base64url (dành cho n và e trong JWKS)."""
    byte_len = (val.bit_length() + 7) // 8
    val_bytes = val.to_bytes(byte_len, byteorder='big')
    return _b64url_encode(val_bytes)

def get_rsa_keys():
    """Tải hoặc tự động khởi tạo cặp khóa RSA 2048-bit dùng cho thuật toán ký RS256."""
    global _private_key, _public_key
    if _private_key is not None and _public_key is not None:
        return _private_key, _public_key

    os.makedirs(KEYS_DIR, exist_ok=True)
    if os.path.exists(PRIVATE_KEY_PATH) and os.path.exists(PUBLIC_KEY_PATH):
        with open(PRIVATE_KEY_PATH, 'rb') as f:
            _private_key = serialization.load_pem_private_key(f.read(), password=None)
        with open(PUBLIC_KEY_PATH, 'rb') as f:
            _public_key = serialization.load_pem_public_key(f.read())
    else:
        # Sinh khóa RSA 2048-bit mới
        _private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        _public_key = _private_key.public_key()
        
        priv_pem = _private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        pub_pem = _public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        with open(PRIVATE_KEY_PATH, 'wb') as f:
            f.write(priv_pem)
        try:
            os.chmod(PRIVATE_KEY_PATH, 0o600)
        except Exception:
            pass
        with open(PUBLIC_KEY_PATH, 'wb') as f:
            f.write(pub_pem)

    return _private_key, _public_key

def get_jwks() -> dict:
    """
    Trả về bộ khóa công khai JSON Web Key Set (JWKS) chuẩn RFC 7517.
    Cho phép các client OIDC tải về để tự xác minh tính hợp lệ của token mà không cần secret.
    """
    _, pub_key = get_rsa_keys()
    pub_numbers = pub_key.public_numbers()
    return {
        "keys": [
            {
                "kty": "RSA",
                "use": "sig",
                "alg": "RS256",
                "kid": KEY_ID,
                "n": _int_to_b64url(pub_numbers.n),
                "e": _int_to_b64url(pub_numbers.e)
            }
        ]
    }

def compute_at_hash(access_token: str) -> str:
    """
    Tính mã băm at_hash cho ID Token theo chuẩn OpenID Connect Core 1.0 Section 3.1.3.6.
    Lấy nửa đầu của SHA-256(access_token) rồi mã hóa base64url.
    """
    digest = hashlib.sha256(access_token.encode('ascii')).digest()
    left_half = digest[:len(digest) // 2]
    return _b64url_encode(left_half)

def create_jwt_rs256(payload: dict, expires_in: int = 3600) -> str:
    """Tạo JWT có chữ ký bất đối xứng RSA-SHA256 (RS256) chuẩn RFC 7519."""
    priv_key, _ = get_rsa_keys()
    now = int(time.time())
    payload_copy = payload.copy()
    payload_copy.setdefault('iat', now)
    payload_copy.setdefault('exp', now + expires_in)
    payload_copy.setdefault('iss', 'https://sso.ptit.edu.vn')
    
    header = {
        "alg": "RS256",
        "typ": "JWT",
        "kid": KEY_ID
    }
    
    encoded_header = _b64url_encode(json.dumps(header, separators=(',', ':')).encode('utf-8'))
    encoded_payload = _b64url_encode(json.dumps(payload_copy, separators=(',', ':')).encode('utf-8'))
    signing_input = f"{encoded_header}.{encoded_payload}".encode('ascii')
    
    signature = priv_key.sign(
        signing_input,
        padding.PKCS1v15(),
        hashes.SHA256()
    )
    return f"{encoded_header}.{encoded_payload}.{_b64url_encode(signature)}"

def verify_jwt_rs256(token: str, expected_aud: str = None, expected_iss: str = None) -> dict:
    """Xác thực chữ ký RS256 và kiểm tra các claim bắt buộc (exp, iat, aud, iss)."""
    parts = token.split('.')
    if len(parts) != 3:
        raise ValueError("Invalid JWT format")
    
    encoded_header, encoded_payload, encoded_signature = parts
    try:
        header = json.loads(_b64url_decode(encoded_header).decode('utf-8'))
    except Exception:
        raise ValueError("Invalid JWT header")

    if header.get('alg') != 'RS256':
        raise ValueError(f"Unsupported JWT algorithm: {header.get('alg')}")

    _, pub_key = get_rsa_keys()
    signing_input = f"{encoded_header}.{encoded_payload}".encode('ascii')
    signature = _b64url_decode(encoded_signature)
    
    try:
        pub_key.verify(signature, signing_input, padding.PKCS1v15(), hashes.SHA256())
    except Exception:
        raise ValueError("Signature mismatch")

    payload = json.loads(_b64url_decode(encoded_payload).decode('utf-8'))
    now = time.time()
    
    if payload.get('exp', 0) < now:
        raise ValueError("Token expired")
    
    if expected_aud:
        token_aud = payload.get('aud')
        if isinstance(token_aud, list):
            if expected_aud not in token_aud:
                raise ValueError(f"Audience mismatch: expected {expected_aud}, got {token_aud}")
        elif token_aud != expected_aud:
            raise ValueError(f"Audience mismatch: expected {expected_aud}, got {token_aud}")

    if expected_iss and payload.get('iss') != expected_iss:
        raise ValueError(f"Issuer mismatch: expected {expected_iss}, got {payload.get('iss')}")

    return payload

def create_jwt(payload: dict, secret_key: str = None, expires_in: int = 3600) -> str:
    """Wrapper tương thích ngược: mặc định sử dụng RS256 chuẩn bảo mật cao."""
    return create_jwt_rs256(payload, expires_in=expires_in)

def verify_jwt(token: str, secret_key: str = None, expected_aud: str = None, expected_iss: str = None) -> dict:
    """Xác thực token: tự động nhận diện RS256 hoặc HS256 (hỗ trợ so sánh thời gian hằng số)."""
    parts = token.split('.')
    if len(parts) != 3:
        raise ValueError("Invalid JWT format")
    try:
        header = json.loads(_b64url_decode(parts[0]).decode('utf-8'))
    except Exception:
        raise ValueError("Invalid JWT header")

    alg = header.get('alg', 'RS256')
    if alg == 'RS256':
        return verify_jwt_rs256(token, expected_aud=expected_aud, expected_iss=expected_iss)
    elif alg == 'HS256':
        if not secret_key:
            raise ValueError("Secret key required for HS256")
        encoded_header, encoded_payload, encoded_signature = parts
        signing_input = f"{encoded_header}.{encoded_payload}".encode('ascii')
        expected_sig = hmac.new(secret_key.encode('utf-8'), signing_input, hashlib.sha256).digest()
        if not hmac.compare_digest(_b64url_encode(expected_sig), encoded_signature):
            raise ValueError("Signature mismatch")
        payload = json.loads(_b64url_decode(encoded_payload).decode('utf-8'))
        if payload.get('exp', 0) < time.time():
            raise ValueError("Token expired")
        if expected_aud and payload.get('aud') != expected_aud:
            raise ValueError("Audience mismatch")
        if expected_iss and payload.get('iss') != expected_iss:
            raise ValueError("Issuer mismatch")
        return payload
    else:
        raise ValueError(f"Unsupported algorithm: {alg}")

# ====================================================================
# PHÂN TÁCH TOKEN PAYLOAD: ACCESS TOKEN & ID TOKEN
# ====================================================================
def create_access_token(user_info: dict, client_id: str, scope: str = "openid profile email groups vlan", expires_in: int = 3600, issuer: str = "https://sso.ptit.edu.vn") -> str:
    """
    Tạo Access Token: Dùng để xác thực và ủy quyền truy cập tài nguyên (Resource Server / UserInfo).
    Chỉ chứa thông tin ủy quyền, phạm vi (scopes) và mã định danh phiên.
    """
    now = int(time.time())
    payload = {
        "iss": issuer,
        "sub": user_info['username'],
        "aud": client_id,
        "client_id": client_id,
        "scope": scope,
        "token_type": "Bearer",
        "jti": user_info.get('jti') or secrets.token_hex(16),
        "iat": now,
        "exp": now + expires_in
    }
    return create_jwt_rs256(payload, expires_in=expires_in)

def create_id_token(user_info: dict, client_id: str, nonce: str = None, access_token: str = None, expires_in: int = 3600, issuer: str = "https://sso.ptit.edu.vn") -> str:
    """
    Tạo ID Token chuẩn OpenID Connect: Dùng để chứng thực danh tính người dùng cho Client App.
    Chứa thông tin hồ sơ người dùng (profile claims), nonce chống replay, và mã băm at_hash.
    """
    now = int(time.time())
    username = user_info['username']
    payload = {
        "iss": issuer,
        "sub": username,
        "aud": client_id,
        "iat": now,
        "exp": now + expires_in,
        "auth_time": user_info.get('auth_time', now),
        "name": user_info.get('name', username),
        "email": user_info.get('email', f"{username}@ptit.edu.vn"),
        "group": user_info.get('group', 'sinhvien'),
        "vlan": user_info.get('vlan', 20)
    }
    if nonce:
        payload["nonce"] = nonce
    if access_token:
        payload["at_hash"] = compute_at_hash(access_token)
    return create_jwt_rs256(payload, expires_in=expires_in)

# ====================================================================
# PKCE (PROOF KEY FOR CODE EXCHANGE - RFC 7636)
# ====================================================================
def verify_pkce(code_verifier: str, code_challenge: str, code_challenge_method: str = "S256") -> bool:
    """Xác thực mã PKCE theo chuẩn RFC 7636 (chống đánh cắp Authorization Code trên Public Clients)."""
    if not code_challenge:
        return True  # Nếu client không dùng PKCE
    if not code_verifier:
        return False

    method = (code_challenge_method or "S256").upper()
    if method == "S256":
        computed_hash = hashlib.sha256(code_verifier.encode('ascii')).digest()
        computed_challenge = _b64url_encode(computed_hash)
        return hmac.compare_digest(computed_challenge, code_challenge)
    elif method == "PLAIN":
        return hmac.compare_digest(code_verifier, code_challenge)
    return False

# ====================================================================
# CLIENT SECRET HASHING & CONSTANT-TIME VERIFICATION
# ====================================================================
def hash_client_secret(secret: str, salt: str = None) -> str:
    """Băm client_secret bằng PBKDF2-HMAC-SHA256 (100,000 vòng) để lưu trữ an toàn."""
    if not salt:
        salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac('sha256', secret.encode('utf-8'), salt.encode('utf-8'), 100000)
    return f"pbkdf2:sha256:100000${salt}${key.hex()}"

def verify_client_secret(stored_secret: str, provided_secret: str) -> bool:
    """
    Xác minh client_secret bằng so khớp hằng số thời gian (hmac.compare_digest) chống Timing Attack.
    Hỗ trợ cả chuỗi đã băm pbkdf2 và tương thích ngược với chuỗi plaintext cũ.
    """
    if not stored_secret or not provided_secret:
        return False

    if stored_secret.startswith("pbkdf2:sha256:"):
        try:
            parts = stored_secret.split('$')
            iterations = int(parts[0].split(':')[-1])
            salt = parts[1]
            expected_hash = parts[2]
            computed = hashlib.pbkdf2_hmac('sha256', provided_secret.encode('utf-8'), salt.encode('utf-8'), iterations).hex()
            return hmac.compare_digest(computed, expected_hash)
        except Exception:
            return False
    else:
        # So sánh chuỗi plaintext bằng constant-time comparison
        return hmac.compare_digest(stored_secret, provided_secret)
