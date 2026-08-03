"""
HTTP clients for the two services recommendation-service needs to call
directly. Both soft-fail (return None) on any error -- the callers already
have a sensible fallback for "no data" from the Phase 1 monolith, so a
downstream outage degrades the feature instead of breaking the endpoint.
"""

import os

import requests

ITINERARY_SERVICE_URL = os.environ.get("ITINERARY_SERVICE_URL", "http://localhost:5002")
USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://localhost:5001")

_TIMEOUT = 3


def get_my_itineraries(auth_header: str) -> list | None:
    """Used by get_recommendations to derive the user's visited-tag
    history. Forwards the caller's own bearer token onward -- itinerary
    -service does its own auth, this service never re-validates it.
    Returns None on any failure, which the caller treats the same as "no
    itinerary history yet" (falls back to pure popularity)."""
    try:
        resp = requests.get(
            f"{ITINERARY_SERVICE_URL}/api/itineraries",
            headers={"Authorization": auth_header},
            timeout=_TIMEOUT,
        )
        if resp.status_code != 200:
            return None
        return resp.json()
    except requests.RequestException:
        return None


def get_user(user_id: str) -> dict | None:
    """Used by add_review to resolve the reviewer's display name. Returns
    None on any failure -- the caller falls back to "Traveler", same as
    the monolith's behavior when the local lookup missed."""
    try:
        resp = requests.get(f"{USER_SERVICE_URL}/api/users/{user_id}", timeout=_TIMEOUT)
        if resp.status_code != 200:
            return None
        return resp.json()
    except requests.RequestException:
        return None
