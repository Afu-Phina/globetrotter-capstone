from flask import Flask


def create_app():
    app = Flask(__name__)

    from app.routes.itineraries import itineraries_bp
    from app.routes.visits import visits_bp

    app.register_blueprint(itineraries_bp, url_prefix="/api/itineraries")
    app.register_blueprint(visits_bp, url_prefix="/api/visits")

    @app.route("/api/health")
    def health():
        return {"status": "ok", "service": "itinerary-service"}

    return app
