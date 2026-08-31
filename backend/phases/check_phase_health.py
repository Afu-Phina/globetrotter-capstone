from backend.phases.phase_app import create_phase_app


def run_check(phase="phase1"):
    app = create_phase_app(phase)
    with app.test_client() as c:
        r = c.get("/api/health")
        print(r.status_code)
        print(r.get_data(as_text=True))


if __name__ == "__main__":
    run_check()
