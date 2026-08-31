from flask import Flask


PHASE_BLUEPRINTS = {
    "phase1": [
        ("app.routes.destinations", "destinations_bp", "/api/destinations"),
    ],
    "phase2": [
        ("app.routes.destinations", "destinations_bp", "/api/destinations"),
        ("app.routes.itineraries", "itineraries_bp", "/api/itineraries"),
    ],
    "phase3": [
        ("app.routes.destinations", "destinations_bp", "/api/destinations"),
        ("app.routes.auth", "auth_bp", "/api/auth"),
    ],
    "full": [
        ("app.routes.auth", "auth_bp", "/api/auth"),
        ("app.routes.destinations", "destinations_bp", "/api/destinations"),
        ("app.routes.itineraries", "itineraries_bp", "/api/itineraries"),
        ("app.routes.recommendations", "recommendations_bp", "/api/recommendations"),
        ("app.routes.visits", "visits_bp", "/api/visits"),
    ]
}


def create_phase_app(phase: str = "phase1"):
    """Create a Flask app limited to blueprints for the given phase.

    This is intentionally non-destructive: it imports existing blueprint
    objects and registers only the ones listed for the phase.
    """
    app = Flask(__name__)

    @app.after_request
    def add_cors_headers(response):
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        return response

    mapping = PHASE_BLUEPRINTS.get(phase)
    if mapping is None:
        raise ValueError(f"Unknown phase: {phase}")

    for module_path, bp_name, url_prefix in mapping:
        module = __import__(module_path, fromlist=[bp_name])
        bp = getattr(module, bp_name)
        app.register_blueprint(bp, url_prefix=url_prefix)

    @app.route("/api/health")
    def health():
        return {"status": "ok", "service": f"globetrotter-backend-{phase}"}

    return app


if __name__ == "__main__":
    import sys

    phase = sys.argv[1] if len(sys.argv) > 1 else "phase1"
    app = create_phase_app(phase)
    app.run(host="0.0.0.0", port=5002)
