"""
AI-powered "ask a question" helper.

Calls Claude to answer free-form questions about a destination, grounded in
that destination's own data (description, category, neighborhood, tags,
and a sample of its reviews) rather than a fixed set of keyword-matched
categories. Falls back to a simple templated answer if no API key is
configured or the request fails, so the feature degrades instead of
breaking the endpoint.
"""

import os

import anthropic

from app.utils.storage import read_all

_MODEL = "claude-opus-5"


def _fallback_answer(destination: dict, question: str) -> str:
    q = question.lower()
    name = destination["name"]

    if any(w in q for w in ["open", "hour", "time", "close"]):
        return f"{name} is generally open during daytime hours. Exact hours can vary, so it's worth checking locally before you go."
    if any(w in q for w in ["where", "location", "located", "address", "find"]):
        return f"{name} is located in the {destination['neighborhood']} area of Yaoundé."
    if any(w in q for w in ["cost", "price", "fee", "ticket", "how much"]):
        return f"Entry fees for {name} can vary and may not always be posted online -- it's best to confirm on-site."
    return (
        f"{destination['description']} If you have a more specific question about "
        f"{name}, try asking about its location, hours, or what makes it worth visiting."
    )


def answer_destination_question(destination: dict, question: str) -> str:
    """
    Answers any free-form question about a destination. Grounds the model in
    the destination's own catalogue data and recent reviews so it doesn't
    invent facts (exact prices, hours) the catalogue doesn't have.
    """
    if not (os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("ANTHROPIC_AUTH_TOKEN")):
        return _fallback_answer(destination, question)

    reviews = [r for r in read_all("reviews") if r["destination_id"] == destination["id"]]
    review_snippets = "\n".join(f'- "{r["comment"]}" ({r["rating"]}/5)' for r in reviews[:5])

    system_prompt = (
        "You are a knowledgeable local travel assistant for GlobeTrotter, helping visitors "
        "learn about destinations in Yaoundé, Cameroon. Answer the traveler's question about "
        "the specific place described below. Be conversational and concise (2-4 sentences "
        "unless the question genuinely needs more), and be honest when the provided data "
        "doesn't cover something -- don't invent specifics like exact prices or hours that "
        "aren't given. You may draw on general knowledge of Yaoundé and Cameroon for helpful "
        "context, but don't contradict the place's own data below.\n\n"
        f"Name: {destination['name']}\n"
        f"Category: {destination['category']}\n"
        f"Neighborhood: {destination['neighborhood']}\n"
        f"Description: {destination['description']}\n"
        f"Tags: {', '.join(destination.get('tags', []))}\n"
        + (f"Recent visitor reviews:\n{review_snippets}\n" if review_snippets else "")
    )

    try:
        client = anthropic.Anthropic()
        response = client.messages.create(
            model=_MODEL,
            max_tokens=1024,
            system=system_prompt,
            output_config={"effort": "low"},
            messages=[{"role": "user", "content": question}],
        )
    except anthropic.AnthropicError:
        return _fallback_answer(destination, question)

    if response.stop_reason == "refusal":
        return _fallback_answer(destination, question)

    text = next((b.text for b in response.content if b.type == "text"), None)
    return text or _fallback_answer(destination, question)
