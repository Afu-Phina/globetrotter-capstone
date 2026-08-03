import os

from flask import Flask


def create_app():
    # static/ lives at the service root (sibling of app/), not inside the
    # app package -- keeps code and static assets separate. Served at
    # /static/... to match the monolith's Flask-default static route,
    # which destination_image.dart's URL-building already assumes.
    static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
    app = Flask(__name__, static_folder=static_dir, static_url_path="/static")

    from app.routes.destinations import destinations_bp
    from app.routes.recommendations import recommendations_bp

    app.register_blueprint(destinations_bp, url_prefix="/api/destinations")
    app.register_blueprint(recommendations_bp, url_prefix="/api/recommendations")

    @app.route("/api/health")
    def health():
        return {"status": "ok", "service": "recommendation-service"}

    return app
