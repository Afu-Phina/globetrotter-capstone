"""Shared AI helpers: Gemini integration and a rule-based fallback.

This module centralizes the simple rule-based fallback and Gemini
integration so multiple services can reuse the same behavior without
duplicating code.
"""
import os
import requests

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-flash-latest"
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"


def fallback_answer(destination: dict, question: str) -> str:
    q = question.lower()
    name = destination.get("name", "This place")

    if any(w in q for w in ["open", "hour", "time", "close"]):
        return f"{name} is generally open during daytime hours. Exact hours can vary, so it's worth checking locally before you go."
    if any(w in q for w in ["where", "location", "located", "address", "find"]):
        return f"{name} is located in the {destination.get('neighborhood','the city')} area of Yaoundé."
    if any(w in q for w in ["cost", "price", "fee", "ticket", "how much"]):
        return f"Entry fees for {name} can vary and may not always be posted online -- it's best to confirm on-site."
    if any(w in q for w in ["what", "about", "why", "worth", "see", "do"]):
        return f"{destination.get('description','')}. It's known for: {', '.join(destination.get('tags', []))}."
    return (
        f"{destination.get('description','')} If you have a more specific question about "
        f"{name}, try asking about its location, hours, or what makes it worth visiting."
    )


def answer_with_gemini(destination: dict, question: str) -> str | None:
    """Return Gemini answer text, or None if Gemini is not configured or fails."""
    if not GEMINI_API_KEY:
        return None

    context_parts = [
        f"Destination: {destination.get('name')}",
        f"Neighborhood: {destination.get('neighborhood')}, Yaoundé, Cameroon",
        f"Category: {destination.get('category')}",
        f"Description: {destination.get('description')}",
    ]
    if destination.get("tags"):
        context_parts.append(f"Known for: {', '.join(destination.get('tags'))}")
    if destination.get("history"):
        context_parts.append(f"History: {destination.get('history')}")
    if destination.get("fun_fact"):
        context_parts.append(f"Fun fact: {destination.get('fun_fact')}")

    prompt = (
        "You are a helpful, honest local travel assistant for a Yaoundé, Cameroon "
        "travel app. Answer the visitor's question about the destination below in "
        "2-4 sentences, in a warm and practical tone. Only use the facts provided -- "
        "if the answer isn't covered by them and you don't have reliable general "
        "knowledge about it, say plainly that you don't have that specific "
        "information rather than guessing.\n\n"
        + f"{chr(10).join(context_parts)}\n\n"
        + f"Visitor's question: {question}"
    )

    try:
        response = requests.post(
            GEMINI_URL,
            headers={
                "Content-Type": "application/json",
                "X-goog-api-key": GEMINI_API_KEY,
            },
            json={"contents": [{"parts": [{"text": prompt}]}]},
            timeout=15,
        )
    except requests.RequestException as e:
        print(f"[shared.ai_helpers] Gemini request failed: {e}")
        return None

    if response.status_code != 200:
        print(f"[shared.ai_helpers] Gemini returned {response.status_code}: {response.text[:500]}")
        return None

    try:
        data = response.json()
        answer = data["candidates"][0]["content"]["parts"][0]["text"].strip()
        if not answer:
            return None
        return answer
    except Exception as e:
        print(f"[shared.ai_helpers] Could not parse Gemini response: {e}. Raw: {response.text[:500]}")
        return None


def answer_destination_question(destination: dict, question: str) -> tuple[str, str | None]:
    """Try Gemini, fall back to rule-based answer. Returns (answer, provider).

    provider is 'gemini' when Gemini was used, otherwise None.
    """
    gemini_ans = answer_with_gemini(destination, question)
    if gemini_ans:
        return gemini_ans, "gemini"
    return fallback_answer(destination, question), None
