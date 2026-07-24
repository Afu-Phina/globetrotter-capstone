import uuid
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, write_all, find_by_id
from app.utils.auth import require_auth

itineraries_bp = Blueprint("itineraries", __name__)


def _is_visible_to(itinerary: dict, user_id: str) -> bool:
    return itinerary["owner_id"] == user_id or user_id in itinerary.get("shared_with", [])


@itineraries_bp.route("", methods=["POST"])
@require_auth
def create_itinerary(current_user_id):
    data = request.get_json(silent=True) or {}
    title = (data.get("title") or "").strip()
    if not title:
        return jsonify({"error": "title is required"}), 400

    itinerary = {
        "id": str(uuid.uuid4()),
        "owner_id": current_user_id,
        "title": title,
        "start_date": data.get("start_date"),
        "end_date": data.get("end_date"),
        "destination_ids": data.get("destination_ids", []),
        "notes": data.get("notes", ""),
        "shared_with": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    itineraries = read_all("itineraries")
    itineraries.append(itinerary)
    write_all("itineraries", itineraries)

    return jsonify(itinerary), 201


@itineraries_bp.route("", methods=["GET"])
@require_auth
def list_itineraries(current_user_id):
    """Returns itineraries the user owns AND ones shared with them."""
    itineraries = read_all("itineraries")
    visible = [i for i in itineraries if _is_visible_to(i, current_user_id)]
    return jsonify(visible), 200


@itineraries_bp.route("/<itinerary_id>", methods=["GET"])
@require_auth
def get_itinerary(current_user_id, itinerary_id):
    itinerary = find_by_id("itineraries", itinerary_id)
    if not itinerary or not _is_visible_to(itinerary, current_user_id):
        return jsonify({"error": "Itinerary not found"}), 404
    return jsonify(itinerary), 200


@itineraries_bp.route("/<itinerary_id>", methods=["PUT"])
@require_auth
def update_itinerary(current_user_id, itinerary_id):
    itineraries = read_all("itineraries")
    itinerary = next((i for i in itineraries if i["id"] == itinerary_id), None)

    if not itinerary or itinerary["owner_id"] != current_user_id:
        return jsonify({"error": "Itinerary not found"}), 404

    data = request.get_json(silent=True) or {}
    for field in ["title", "start_date", "end_date", "destination_ids", "notes"]:
        if field in data:
            itinerary[field] = data[field]

    write_all("itineraries", itineraries)
    return jsonify(itinerary), 200


@itineraries_bp.route("/<itinerary_id>", methods=["DELETE"])
@require_auth
def delete_itinerary(current_user_id, itinerary_id):
    itineraries = read_all("itineraries")
    itinerary = next((i for i in itineraries if i["id"] == itinerary_id), None)

    if not itinerary or itinerary["owner_id"] != current_user_id:
        return jsonify({"error": "Itinerary not found"}), 404

    itineraries = [i for i in itineraries if i["id"] != itinerary_id]
    write_all("itineraries", itineraries)
    return jsonify({"message": "Itinerary deleted"}), 200


@itineraries_bp.route("/<itinerary_id>/share", methods=["POST"])
@require_auth
def share_itinerary(current_user_id, itinerary_id):
    """Share an itinerary with another registered user by email."""
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    if not email:
        return jsonify({"error": "email is required"}), 400

    users = read_all("users")
    target_user = next((u for u in users if u["email"] == email), None)
    if not target_user:
        return jsonify({"error": "No user found with that email"}), 404

    itineraries = read_all("itineraries")
    itinerary = next((i for i in itineraries if i["id"] == itinerary_id), None)
    if not itinerary or itinerary["owner_id"] != current_user_id:
        return jsonify({"error": "Itinerary not found"}), 404

    if target_user["id"] == current_user_id:
        return jsonify({"error": "You cannot share an itinerary with yourself"}), 400

    if target_user["id"] not in itinerary["shared_with"]:
        itinerary["shared_with"].append(target_user["id"])
        write_all("itineraries", itineraries)

    return jsonify(itinerary), 200
