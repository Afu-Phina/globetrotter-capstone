"""
JWT verification only -- see itinerary-service/app/utils/auth.py for the
same trimmed pattern. This service never issues tokens or touches
passwords.
"""

import os
from functools import wraps

import jwt
from flask import request, jsonify

SECRET_KEY = os.environ.get("GLOBETROTTER_SECRET", "dev-secret-change-me")


def decode_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    except jwt.PyJWTError:
        return None


def require_auth(f):
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
