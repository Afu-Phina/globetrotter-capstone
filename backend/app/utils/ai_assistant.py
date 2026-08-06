"""
Real LLM-backed Q&A about a destination, using Google's Gemini API.

Falls back to the old rule-based answer if the API key is missing, the
request fails, or Gemini returns something unusable -- the assistant
should degrade gracefully rather than break the whole feature when one
external dependency has a bad day.
"""

import os
import requests

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.0-flash"
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"


def _rule_based_fallback(destination: dict, question: str) -> str:
    q = question.lower()
    name = destination["name"]

    if any(w in q for w in ["open", "hour", "time", "close"]):
        return f"{name} is generally open during daytime hours. Exact hours can vary, so it's worth checking locally before you go."
    elif any(w in q for w in ["where", "location", "located", "address", "find"]):
        return f"{name} is located in the {destination['neighborhood']} area of Yaoundé."
    elif any(w in q for w in ["cost", "price", "fee", "ticket", "how much"]):
        return f"Entry fees for {name} can vary and may not always be posted online -- it's best to confirm on-site."
    elif any(w in q for w in ["what", "about", "why", "worth", "see", "do"]):
        return f"{destination['description']} It's known for: {', '.join(destination.get('tags', []))}."
    return (
        f"{destination['description']} If you have a more specific question about "
        f"{name}, try asking about its location, hours, or what makes it worth visiting."
    )


def answer_question(destination: dict, question: str) -> tuple[str, bool]:
    """Returns (answer, used_ai). used_ai=False means the fallback ran."""
    if not GEMINI_API_KEY:
        return _rule_based_fallback(destination, question), False

    context_parts = [
        f"Destination: {destination['name']}",
        f"Neighborhood: {destination['neighborhood']}, Yaoundé, Cameroon",
        f"Category: {destination['category']}",
        f"Description: {destination['description']}",
    ]
    if destination.get("tags"):
        context_parts.append(f"Known for: {', '.join(destination['tags'])}")
    if destination.get("history"):
        context_parts.append(f"History: {destination['history']}")
    if destination.get("fun_fact"):
        context_parts.append(f"Fun fact: {destination['fun_fact']}")

    prompt = (
        "You are a helpful, honest local travel assistant for a Yaoundé, Cameroon "
        "travel app. Answer the visitor's question about the destination below in "
        "2-4 sentences, in a warm and practical tone. Only use the facts provided -- "
        "if the answer isn't covered by them and you don't have reliable general "
        "knowledge about it, say plainly that you don't have that specific "
        "information rather than guessing.\n\n"
        f"{chr(10).join(context_parts)}\n\n"
        f"Visitor's question: {question}"
    )

    try:
        response = requests.post(
            GEMINI_URL,
            params={"key": GEMINI_API_KEY},
            json={"contents": [{"parts": [{"text": prompt}]}]},
            timeout=15,
        )
    except requests.RequestException:
        return _rule_based_fallback(destination, question), False

    if response.status_code != 200:
        return _rule_based_fallback(destination, question), False

    try:
        data = response.json()
        answer = data["candidates"][0]["content"]["parts"][0]["text"].strip()
        if not answer:
            raise ValueError("empty response")
        return answer, True
    except (KeyError, IndexError, ValueError):
        return _rule_based_fallback(destination, question), False
