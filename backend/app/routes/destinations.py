from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, find_by_id

destinations_bp = Blueprint("destinations", __name__)


@destinations_bp.route("", methods=["GET"])
def list_destinations():
    """
    GET /api/destinations
    GET /api/destinations?q=market            -> text search (name/description/tags)
    GET /api/destinations?category=Nature      -> filter by category
    """
    destinations = read_all("destinations")

    query = (request.args.get("q") or "").strip().lower()
    category = (request.args.get("category") or "").strip().lower()

    if query:
        destinations = [
            d for d in destinations
            if query in d["name"].lower()
            or query in d["description"].lower()
            or any(query in tag.lower() for tag in d.get("tags", []))
        ]

    if category:
        destinations = [d for d in destinations if d["category"].lower() == category]

    # Default ordering: most popular first.
    destinations.sort(key=lambda d: d.get("popularity", 0), reverse=True)

    return jsonify(destinations), 200


@destinations_bp.route("/<destination_id>", methods=["GET"])
def get_destination(destination_id):
    destination = find_by_id("destinations", destination_id)
    if not destination:
        return jsonify({"error": "Destination not found"}), 404
    return jsonify(destination), 200
