"""Monolith adapter that delegates to shared AI helpers.

This file keeps the original `answer_question(destination, question)` API
but delegates actual work to `shared.ai_helpers` so the logic is reused.
"""

from shared.ai_helpers import answer_destination_question


def answer_question(destination: dict, question: str) -> tuple[str, bool]:
    """Returns (answer, used_ai). used_ai=False means the fallback ran."""
    answer, provider = answer_destination_question(destination, question)
    return answer, (provider is not None)