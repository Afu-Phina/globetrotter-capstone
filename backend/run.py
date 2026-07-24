from app import create_app

app = create_app()

if __name__ == "__main__":
    # host=0.0.0.0 so the Flutter app (emulator/device) can reach it on the network.
    app.run(host="0.0.0.0", port=5000, debug=True)
