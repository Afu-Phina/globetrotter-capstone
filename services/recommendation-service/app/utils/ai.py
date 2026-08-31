"""Recommendation-service AI helper.

This module keeps the Claude/Anthropic integration but reuses the shared
fallback logic from `shared.ai_helpers` so the two implementations stay
consistent.
"""

import os

import anthropic

from app.utils.storage import read_all
from shared.ai_helpers import fallback_answer

_MODEL = "claude-opus-5"


def answer_destination_question(destination: dict, question: str) -> str:
    if not (os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("ANTHROPIC_AUTH_TOKEN")):
        return fallback_answer(destination, question)

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
        return fallback_answer(destination, question)

    if response.stop_reason == "refusal":
        return fallback_answer(destination, question)

    text = next((b.text for b in response.content if b.type == "text"), None)
    return text or fallback_answer(destination, question)
