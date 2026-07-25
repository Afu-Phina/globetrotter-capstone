import uuid
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all, write_all, find_by_id
from app.utils.auth import require_auth

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

    return jsonify([_with_rating(d) for d in destinations]), 200


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

    users = read_all("users")
    author = next((u for u in users if u["id"] == current_user_id), None)

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
# Ask a question -- rule-based FAQ, not a real AI model. Matches keywords in
# the question against the destination's own description/tags/category and
# returns a templated answer built from that data. Good enough for a Phase
# 1-adjacent demo; a real model would need hosted inference we don't have
# here.
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

    q = question.lower()
    name = destination["name"]

    if any(w in q for w in ["open", "hour", "time", "close"]):
        answer = f"{name} is generally open during daytime hours. Exact hours can vary, so it's worth checking locally before you go."
    elif any(w in q for w in ["where", "location", "located", "address", "find"]):
        answer = f"{name} is located in the {destination['neighborhood']} area of Yaoundé."
    elif any(w in q for w in ["cost", "price", "fee", "ticket", "how much"]):
        answer = f"Entry fees for {name} can vary and may not always be posted online -- it's best to confirm on-site."
    elif any(w in q for w in ["what", "about", "why", "worth", "see", "do"]):
        answer = f"{destination['description']} It's known for: {', '.join(destination.get('tags', []))}."
    else:
        answer = (
            f"{destination['description']} If you have a more specific question about "
            f"{name}, try asking about its location, hours, or what makes it worth visiting."
        )

    return jsonify({"question": question, "answer": answer}), 200
