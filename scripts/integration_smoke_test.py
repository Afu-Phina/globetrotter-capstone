#!/usr/bin/env python3
"""Simple integration smoke test for the monolith API.

Runs: register -> login -> create itinerary -> add review -> ask -> book visit
"""
import time
import requests

BASE = "http://127.0.0.1:5000/api"


def main():
    ts = int(time.time())
    email = f"smoketest{ts}@example.com"
    password = "password123"

    print("1) Registering user...")
    r = requests.post(f"{BASE}/auth/register", json={"name": "Smoke Tester", "email": email, "password": password})
    print(r.status_code, r.text)
    if r.status_code not in (200, 201):
        return
    token = r.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    print("2) Creating itinerary...")
    payload = {"title": "Smoke Test Trip", "destination_ids": ["dest-001"]}
    r = requests.post(f"{BASE}/itineraries", json=payload, headers=headers)
    print(r.status_code, r.text)

    print("3) Adding a review (authenticated)...")
    review = {"rating": 5, "comment": "Amazing place! Smoke test."}
    r = requests.post(f"{BASE}/destinations/dest-001/reviews", json=review, headers=headers)
    print(r.status_code, r.text)

    print("4) Asking AI-backed question (fallback expected)...")
    r = requests.post(f"{BASE}/destinations/dest-001/ask", json={"question": "What are the opening hours?"})
    print(r.status_code, r.text)

    print("5) Booking a guided visit (authenticated)...")
    visit = {"destination_id": "dest-001", "date": "2026-09-05", "time": "10:00", "num_people": 2}
    r = requests.post(f"{BASE}/visits", json=visit, headers=headers)
    print(r.status_code, r.text)


if __name__ == "__main__":
    main()
