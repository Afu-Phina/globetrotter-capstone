"""
Recommendations, Phase 2 style.

Same scoring logic as the Phase 1 monolith (tag overlap with the user's own
itineraries + popularity), but "the user's own itineraries" is now a real
network call to itinerary-service instead of a local read_all() -- this
service owns the destinations catalogue, not itinerary data. Falls back to
the same pure-popularity ranking the monolith used for a user with no
itinerary history if that call fails, so a downstream outage degrades the
personalization, not the endpoint.
"""

from flask import Blueprint, request, jsonify

from app.utils.storage import read_all
from app.utils.auth import require_auth
from app.utils.clients import get_my_itineraries

recommendations_bp = Blueprint("recommendations", __name__)


@recommendations_bp.route("", methods=["GET"])
@require_auth
def get_recommendations(current_user_id):
    destinations = read_all("destinations")

    auth_header = request.headers.get("Authorization", "")
    itineraries = get_my_itineraries(auth_header) or []
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
