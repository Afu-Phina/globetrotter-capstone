import uuid

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, insert, find_by_id
from app.utils.auth import hash_password, verify_password, generate_token

api_bp = Blueprint("api", __name__)


def _public(user: dict) -> dict:
    return {"id": user["id"], "name": user["name"], "email": user["email"]}


@api_bp.route("/auth/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not name or not email or not password:
        return jsonify({"error": "name, email and password are required"}), 400
    if len(password) < 6:
        return jsonify({"error": "password must be at least 6 characters"}), 400

    users = read_all("users")
    if any(u["email"] == email for u in users):
        return jsonify({"error": "An account with this email already exists"}), 409

    user = {
        "id": str(uuid.uuid4()),
        "name": name,
        "email": email,
        "password_hash": hash_password(password),
    }
    insert("users", user)

    token = generate_token(user["id"])
    return jsonify({"token": token, "user": _public(user)}), 201


@api_bp.route("/auth/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    users = read_all("users")
    user = next((u for u in users if u["email"] == email), None)

    if not user or not verify_password(password, user["password_hash"]):
        return jsonify({"error": "Invalid email or password"}), 401

    token = generate_token(user["id"])
    return jsonify({"token": token, "user": _public(user)}), 200


# ---------------------------------------------------------------------------
# Internal lookup endpoints -- called by itinerary-service (share by email)
# and recommendation-service (resolve a reviewer's display name). Public
# fields only, never password_hash.
# ---------------------------------------------------------------------------

@api_bp.route("/users/<user_id>", methods=["GET"])
def get_user(user_id):
    user = find_by_id("users", user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(_public(user)), 200


@api_bp.route("/users", methods=["GET"])
def lookup_user_by_email():
    email = (request.args.get("email") or "").strip().lower()
    if not email:
        return jsonify({"error": "email query parameter is required"}), 400

    users = read_all("users")
    user = next((u for u in users if u["email"] == email), None)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(_public(user)), 200
