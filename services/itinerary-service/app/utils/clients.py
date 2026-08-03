"""
HTTP clients for the two services itinerary-service needs to call directly
(service-to-service, not routed back through the gateway). Both calls used
to be in-process function calls in the Phase 1 monolith.
"""

import os

import requests

RECOMMENDATION_SERVICE_URL = os.environ.get(
    "RECOMMENDATION_SERVICE_URL", "http://localhost:5003"
)
USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://localhost:5001")

_TIMEOUT = 3


def get_destination(destination_id: str) -> dict | None:
    """Used by book_visit to validate a destination_id and get its name.
    Any failure (not found, timeout, service down) returns None -- the
    caller treats that as an invalid destination_id, same as the monolith's
    find_by_id() returning None."""
    try:
        resp = requests.get(
            f"{RECOMMENDATION_SERVICE_URL}/api/destinations/{destination_id}",
            timeout=_TIMEOUT,
        )
        if resp.status_code != 200:
            return None
        return resp.json()
    except requests.RequestException:
        return None


def find_user_by_email(email: str) -> dict | None:
    """Used by share_itinerary to resolve an email to a user id. Any
    failure returns None -- the caller reports "no user found", same as
    the monolith's local lookup miss."""
    try:
        resp = requests.get(
            f"{USER_SERVICE_URL}/api/users",
            params={"email": email},
            timeout=_TIMEOUT,
        )
        if resp.status_code != 200:
            return None
        return resp.json()
    except requests.RequestException:
        return None
