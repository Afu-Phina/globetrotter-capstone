"""
API Gateway -- the single entry point the Flutter app talks to. Externally
this looks exactly like the Phase 1 monolith (same host:port, same /api/*
paths, same /static/images/... path for photos) so the frontend needs zero
changes. Internally it forwards each request to the service that owns
that path, over the Docker network (or localhost, for local verification).

A thin Flask + requests reverse proxy rather than nginx: nginx isn't
installed in the dev sandbox this was built in, and Docker isn't runnable
there either, so an nginx config could never actually be exercised before
handoff. This gateway is just a 4th Flask process, provable with the same
run-it-locally-and-curl-it approach as the three backend services.
"""

import os

import requests
from flask import Flask, request, Response

USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://localhost:5001")
ITINERARY_SERVICE_URL = os.environ.get("ITINERARY_SERVICE_URL", "http://localhost:5002")
RECOMMENDATION_SERVICE_URL = os.environ.get(
    "RECOMMENDATION_SERVICE_URL", "http://localhost:5003"
)

# Checked in order, first prefix match wins.
ROUTES = [
    ("/api/auth", USER_SERVICE_URL),
    ("/api/users", USER_SERVICE_URL),
    ("/api/itineraries", ITINERARY_SERVICE_URL),
    ("/api/visits", ITINERARY_SERVICE_URL),
    ("/api/destinations", RECOMMENDATION_SERVICE_URL),
    ("/api/recommendations", RECOMMENDATION_SERVICE_URL),
    # Destination photos -- served at the root /static/... path (not under
    # /api) by recommendation-service, same as the monolith's Flask-default
    # static route. Missing this silently falls back to placeholder images
    # in the app rather than erroring, so it's easy to miss in testing.
    ("/static", RECOMMENDATION_SERVICE_URL),
]

# Headers that are per-hop and must not be forwarded either direction.
_HOP_BY_HOP = {
    "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
    "te", "trailers", "transfer-encoding", "upgrade", "host", "content-length",
}

app = Flask(__name__)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    return response


@app.route("/api/health")
def health():
    return {"status": "ok", "service": "gateway"}


def _target_for(path: str) -> str | None:
    for prefix, base_url in ROUTES:
        if path == prefix or path.startswith(prefix + "/"):
            return base_url
    return None


@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
def proxy(path):
    full_path = f"/{path}"

    if request.method == "OPTIONS":
        # CORS preflight -- answered directly, never forwarded.
        return Response(status=204)

    base_url = _target_for(full_path)
    if base_url is None:
        return {"error": "Not found"}, 404

    forward_headers = {
        k: v for k, v in request.headers.items() if k.lower() not in _HOP_BY_HOP
    }

    try:
        upstream = requests.request(
            method=request.method,
            url=f"{base_url}{full_path}",
            headers=forward_headers,
            params=request.args,
            data=request.get_data(),
            timeout=15,
        )
    except requests.RequestException:
        return {"error": "Upstream service unavailable"}, 502

    response_headers = [
        (k, v) for k, v in upstream.headers.items() if k.lower() not in _HOP_BY_HOP
    ]
    return Response(upstream.content, status=upstream.status_code, headers=response_headers)
