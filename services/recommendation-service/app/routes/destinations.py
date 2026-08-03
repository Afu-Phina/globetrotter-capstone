import uuid
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, write_all, find_by_id
from app.utils.auth import require_auth
from app.utils.clients import get_user
from app.utils.ai import answer_destination_question

destinations_bp = Blueprint("destinations", __name__)


def _rating_summary(destination_id: str) -> dict:
    reviews = [r for r in read_all("reviews") if r["destination_id"] == destination_id]
    if not reviews:
        return {"average_rating": None, "review_count": 0}
    avg = sum(r["rating"] for r in reviews) / len(reviews)
    return {"average_rating": round(avg, 1), "review_count": len(reviews)}


def _with_rating(destination: dict) -> dict:
    return {**destination, **_rating_summary(destination["id"])}


@destinations_bp.route("", methods=["GET"])
def list_destinations():
    """
    GET /api/destinations
    GET /api/destinations?q=market            -> text search (name/description/tags)
    GET /api/destinations?category=Nature      -> filter by category
    GET /api/destinations?limit=8&offset=0     -> pagination, for "Load More"
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

    destinations.sort(key=lambda d: d.get("popularity", 0), reverse=True)

    try:
        offset = max(int(request.args.get("offset", 0)), 0)
    except ValueError:
        offset = 0
    try:
        limit = int(request.args["limit"]) if "limit" in request.args else None
    except ValueError:
        limit = None

    total = len(destinations)
    if limit is not None:
        destinations = destinations[offset:offset + limit]
    elif offset:
        destinations = destinations[offset:]

    with_ratings = [_with_rating(d) for d in destinations]
    return jsonify({"items": with_ratings, "total": total}), 200


@destinations_bp.route("/<destination_id>", methods=["GET"])
def get_destination(destination_id):
    destination = find_by_id("destinations", destination_id)
    if not destination:
        return jsonify({"error": "Destination not found"}), 404
    return jsonify(_with_rating(destination)), 200


# ---------------------------------------------------------------------------
# Reviews
# ---------------------------------------------------------------------------

@destinations_bp.route("/<destination_id>/reviews", methods=["GET"])
def list_reviews(destination_id):
    reviews = [r for r in read_all("reviews") if r["destination_id"] == destination_id]
    reviews.sort(key=lambda r: r["created_at"], reverse=True)
    return jsonify(reviews), 200


@destinations_bp.route("/<destination_id>/reviews", methods=["POST"])
@require_auth
def add_review(current_user_id, destination_id):
    destination = find_by_id("destinations", destination_id)
    if not destination:
        return jsonify({"error": "Destination not found"}), 404

    data = request.get_json(silent=True) or {}
    rating = data.get("rating")
    comment = (data.get("comment") or "").strip()

    if not isinstance(rating, int) or rating < 1 or rating > 5:
        return jsonify({"error": "rating must be an integer from 1 to 5"}), 400
    if not comment:
        return jsonify({"error": "comment is required"}), 400

    author = get_user(current_user_id)

    review = {
        "id": str(uuid.uuid4()),
        "destination_id": destination_id,
        "user_id": current_user_id,
        "author_name": author["name"] if author else "Traveler",
        "rating": rating,
        "comment": comment,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    reviews = read_all("reviews")
    reviews.append(review)
    write_all("reviews", reviews)

    return jsonify(review), 201


# ---------------------------------------------------------------------------
# Ask a question -- free-form Q&A backed by Claude (see app/utils/ai.py),
# grounded in the destination's own catalogue data and reviews so it doesn't
# invent facts. Falls back to a templated answer if no API key is
# configured or the request fails.
# ---------------------------------------------------------------------------

@destinations_bp.route("/<destination_id>/ask", methods=["POST"])
def ask_question(destination_id):
    destination = find_by_id("destinations", destination_id)
    if not destination:
        return jsonify({"error": "Destination not found"}), 404

    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()
    if not question:
        return jsonify({"error": "question is required"}), 400

    answer = answer_destination_question(destination, question)
    return jsonify({"question": question, "answer": answer}), 200
