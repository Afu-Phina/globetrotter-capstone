import uuid
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, write_all
from app.utils.auth import require_auth
from app.utils.clients import get_destination

visits_bp = Blueprint("visits", __name__)


@visits_bp.route("", methods=["POST"])
@require_auth
def book_visit(current_user_id):
    data = request.get_json(silent=True) or {}
    destination_id = data.get("destination_id")
    date = (data.get("date") or "").strip()
    time = (data.get("time") or "").strip()
    num_people = data.get("num_people")

    destination = get_destination(destination_id) if destination_id else None
    if not destination:
        return jsonify({"error": "A valid destination_id is required"}), 400
    if not date or not time:
        return jsonify({"error": "date and time are required"}), 400
    if not isinstance(num_people, int) or num_people < 1:
        return jsonify({"error": "num_people must be a positive integer"}), 400

    visit = {
        "id": str(uuid.uuid4()),
        "user_id": current_user_id,
        "destination_id": destination_id,
        "destination_name": destination["name"],
        "date": date,
        "time": time,
        "num_people": num_people,
        "status": "confirmed",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    visits = read_all("visits")
    visits.append(visit)
    write_all("visits", visits)

    return jsonify(visit), 201


@visits_bp.route("", methods=["GET"])
@require_auth
def list_my_visits(current_user_id):
    visits = [v for v in read_all("visits") if v["user_id"] == current_user_id]
    visits.sort(key=lambda v: v["created_at"], reverse=True)
    return jsonify(visits), 200


@visits_bp.route("/<visit_id>", methods=["DELETE"])
@require_auth
def cancel_visit(current_user_id, visit_id):
    visits = read_all("visits")
    visit = next((v for v in visits if v["id"] == visit_id), None)

    if not visit or visit["user_id"] != current_user_id:
        return jsonify({"error": "Visit not found"}), 404

    visit["status"] = "cancelled"
    write_all("visits", visits)
    return jsonify(visit), 200
