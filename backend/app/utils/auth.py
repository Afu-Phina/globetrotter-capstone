"""
Auth helpers: password hashing + JWT issue/verify + a decorator that
protects routes. Kept separate from routes/auth.py so any blueprint
(itineraries, sharing) can import `require_auth` without circular imports.
"""

import hashlib
import hmac
import os
import time
from functools import wraps

import jwt
from flask import request, jsonify

# In a real deployment this comes from an environment variable.
# Fine as a fixed dev secret for Phase 1 (single process, not exposed).
SECRET_KEY = os.environ.get("GLOBETROTTER_SECRET", "dev-secret-change-me")
TOKEN_EXPIRY_SECONDS = 60 * 60 * 24 * 7  # 7 days


def hash_password(password: str) -> str:
    """
    Salted SHA-256 hash, stored as 'salt$hash'.
    Not bcrypt/argon2 (those need extra native deps we can't install in
    this sandbox), but far better than plaintext, and enough for a
    coursework Phase 1. Swap for bcrypt/argon2 before any real deployment.
    """
    salt = os.urandom(16).hex()
    digest = hashlib.sha256((salt + password).encode()).hexdigest()
    return f"{salt}${digest}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt, digest = stored_hash.split("$")
    except ValueError:
        return False
    expected = hashlib.sha256((salt + password).encode()).hexdigest()
    return hmac.compare_digest(expected, digest)


def generate_token(user_id: str) -> str:
    payload = {
        "user_id": user_id,
        "exp": int(time.time()) + TOKEN_EXPIRY_SECONDS,
        "iat": int(time.time()),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")


def decode_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    except jwt.PyJWTError:
        return None


def require_auth(f):
    """
    Decorator for protected routes. Reads 'Authorization: Bearer <token>',
    validates it, and passes the decoded user_id into the route as
    `current_user_id`.
    """

    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401

        token = auth_header.split(" ", 1)[1]
        payload = decode_token(token)
        if not payload:
            return jsonify({"error": "Invalid or expired token"}), 401

        return f(*args, current_user_id=payload["user_id"], **kwargs)

    return wrapper
