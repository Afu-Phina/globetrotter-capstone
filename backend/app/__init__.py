from flask import Flask


def create_app():
    """
    Application factory pattern.

    Why a factory instead of a global `app = Flask(__name__)`?
    - Lets us create multiple instances (useful for testing).
    - Keeps configuration and blueprint registration in one clear place.
    - As the app grows (Phase 2 microservices later), each service can
      reuse this same pattern independently.
    """
    app = Flask(__name__)

    # Allow the Flutter app (running on a different host/port) to call this API.
    # Handled manually here instead of via flask-cors, so we don't add an
    # extra dependency for one small piece of behavior.
    @app.after_request
    def add_cors_headers(response):
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        return response

    # Register blueprints (one per resource area).
    from app.routes.auth import auth_bp
    from app.routes.destinations import destinations_bp
    from app.routes.itineraries import itineraries_bp
    from app.routes.recommendations import recommendations_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(destinations_bp, url_prefix="/api/destinations")
    app.register_blueprint(itineraries_bp, url_prefix="/api/itineraries")
    app.register_blueprint(recommendations_bp, url_prefix="/api/recommendations")

    @app.route("/api/health")
    def health():
        return {"status": "ok", "service": "globetrotter-backend"}

    return app
