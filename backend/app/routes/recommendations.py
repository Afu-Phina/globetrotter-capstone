"""
Recommendations, Phase 1 style.

The slide's requirement is: "recommendations based on user preferences,
past trips, and popularity." For Phase 1 (monolith, no ML infra yet) we
implement this as clear, explainable rules rather than a model:

1. Look at destinations already in the user's itineraries -> collect tags.
2. Score every destination NOT yet in an itinerary by:
   - +3 per matching tag with the user's history
   - + popularity score (0-100), weighted down so tag-match dominates
3. If the user has no itinerary history yet, fall back to pure popularity.

This is intentionally simple and easy to explain in a viva/demo -- and it's
a clean seam to swap in a real ML-based recommender in a later phase
without changing the route's contract (still returns a ranked list).
"""

from flask import Blueprint, jsonify

from app.utils.storage import read_all
from app.utils.auth import require_auth

recommendations_bp = Blueprint("recommendations", __name__)


@recommendations_bp.route("", methods=["GET"])
@require_auth
def get_recommendations(current_user_id):
    destinations = read_all("destinations")
    itineraries = read_all("itineraries")

    my_itineraries = [i for i in itineraries if i["owner_id"] == current_user_id]
    visited_ids = {
        dest_id
        for itinerary in my_itineraries
        for dest_id in itinerary.get("destination_ids", [])
    }

    visited_tags = set()
    for dest in destinations:
        if dest["id"] in visited_ids:
            visited_tags.update(dest.get("tags", []))

    candidates = [d for d in destinations if d["id"] not in visited_ids]

    def score(dest):
        tag_overlap = len(set(dest.get("tags", [])) & visited_tags)
        return tag_overlap * 3 + dest.get("popularity", 0) * 0.05

    candidates.sort(key=score, reverse=True)

    return jsonify(candidates[:6]), 200
