#!/usr/bin/env python3
"""Advisory OpenAI review for the current PR diff.

Reads `diff.patch` plus project context docs, asks an OpenAI reasoning model
for grouped observations, and writes `review.md` for the workflow to post
as a PR comment. This script is advisory: model outages, timeouts, or
missing secrets never fail the job — they produce a short fallback body.

Environment:
    OPENAI_API_KEY          required for a real call; if unset the script
                            writes a one-line fallback and exits 0.
    MODEL                   model id (default: gpt-5.5).
    MAX_COMPLETION_TOKENS   response-token cap (default: 4000).
    MAX_DIFF_BYTES          skip review if diff exceeds this (default: 51200).
    GITHUB_SHA              optional; included in the footer for traceability.
"""

from __future__ import annotations

import os
import pathlib
import sys
import textwrap


REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
DIFF_PATH = REPO_ROOT / "diff.patch"
OUTPUT_PATH = REPO_ROOT / "review.md"

CONTEXT_FILES = [
    REPO_ROOT / "CLAUDE.md",
    REPO_ROOT / "docs" / "architecture.md",
    REPO_ROOT / "docs" / "gdd.md",
    REPO_ROOT / "docs" / "sound_design.md",
]


SYSTEM_PROMPT = """\
You are an advisory reviewer on a pull request for a pixel-art roguelite
RPG (pre-alpha, Godot 4.6, GDScript-only, shipping to Steam + Switch).
Project context files follow in the USER message. Read them once, then
review the PR diff.

Return grouped observations only. NEVER emit a verdict, approve/reject
signal, or overall merge recommendation. Do not prefix with "LGTM",
"Requested changes", or similar. Observations only.

Focus areas — scan the diff for:

1. Godot architecture quality — idiomatic Godot 4 patterns: signals over
   direct calls where decoupling matters, past-tense signal names, scene
   composition over inheritance, Resource subclasses for data (not duck-
   typed dicts), autoload hygiene, small single-purpose components/nodes,
   typed @export properties for inspector wiring, EventBus-only cross-
   system communication.

2. Video-game design fundamentals — does the change feel like a good
   game decision? Look for: player agency (predictable, readable outcomes),
   meaningful choices (no dominant options), clear feedback loops
   (input -> response -> consequence), escalation and pacing, fairness vs
   challenge, and whether it adds or subtracts texture (surprise, juice,
   personality). If the change resembles a pattern from a known-successful
   game, say so concretely. Flag anti-patterns (grind without payoff,
   arbitrary hidden information, input-to-outcome gaps). Stay high-level,
   no specific numbers. It is OK and encouraged to emit nothing here if
   the change is purely mechanical with no gameplay impact.

3. Extensibility — numbers, timings, and content live in .tres (data-
   driven, not hardcoded in scripts), composable conditions/actions (not
   switch-on-string dispatch buried in logic), TurnManager.SchedulingModel
   stays swappable, no hidden couplings across the data/systems/UI layers,
   no premature abstractions either.

4. Security — no hardcoded API keys/tokens/credentials (including in
   .tres/.tscn/JSON), no logging of secrets or environment variables, no
   arbitrary-path file reads at runtime, no OS.execute() or shell-outs
   with user-controlled strings, .gitignore still covers any secret-
   bearing file touched by the diff.

HARD CONSTRAINTS:
- Do NOT suggest refactors outside the diff. Every observation must
  reference lines the PR actually touches.
- Do NOT comment on missing tests. The project has no test suite yet and
  that is by design for now.
- Do NOT flag style, formatting, or naming issues that gdlint or
  gdformat already catch. That is the blocking workflow's job.
- Do NOT emit a verdict or merge recommendation anywhere.
- Prefer silence over filler. If a focus area has nothing real to flag,
  OMIT that section entirely. Do not write "looks good" or "no issues".

Output format (Markdown). Omit sections with no findings. If you have no
observations at all, output EXACTLY this single line and nothing else:

No observations from automated review on this diff.

Otherwise use these section headings verbatim (include only the sections
with findings):

## Godot architecture
- <observation, with file:line reference> -- <one-sentence why it matters>

## Gamer-first patterns
- ...

## Extensibility
- ...

## Security
- ...
"""


def read_text_safely(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def write_review(body: str) -> None:
    OUTPUT_PATH.write_text(body, encoding="utf-8")


def fallback(reason: str) -> int:
    write_review(f"_Automated review skipped: {reason}._\n")
    return 0


def main() -> int:
    if not os.environ.get("OPENAI_API_KEY"):
        return fallback("`OPENAI_API_KEY` is not configured on this repo")

    diff = read_text_safely(DIFF_PATH)
    if not diff.strip():
        write_review("No observations from automated review on this diff.\n")
        return 0

    max_bytes = int(os.environ.get("MAX_DIFF_BYTES", "51200"))
    if len(diff.encode("utf-8")) > max_bytes:
        return fallback(
            f"diff exceeds {max_bytes} bytes; large refactors get human-only review"
        )

    try:
        from openai import OpenAI
    except ImportError as exc:
        return fallback(f"`openai` SDK not installed ({exc})")

    context_parts: list[str] = []
    for path in CONTEXT_FILES:
        content = read_text_safely(path)
        if content:
            rel = path.relative_to(REPO_ROOT)
            context_parts.append(f"=== {rel} ===\n{content}")
    context_blob = "\n\n".join(context_parts)

    model = os.environ.get("MODEL", "gpt-5.5")
    max_completion = int(os.environ.get("MAX_COMPLETION_TOKENS", "4000"))

    user_payload = textwrap.dedent(
        """\
        PROJECT CONTEXT (read before reviewing):

        {context}

        ===== END CONTEXT =====

        PR DIFF:

        ```diff
        {diff}
        ```
        """
    ).format(context=context_blob, diff=diff)

    try:
        client = OpenAI()
        resp = client.chat.completions.create(
            model=model,
            max_completion_tokens=max_completion,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_payload},
            ],
        )
        review = (resp.choices[0].message.content or "").strip()
    except Exception as exc:  # noqa: BLE001 - advisory workflow, never hard-fail
        return fallback(f"model call failed ({type(exc).__name__}: {exc})")

    if not review:
        review = "No observations from automated review on this diff."

    sha = os.environ.get("GITHUB_SHA", "HEAD")[:7]
    header = "<!-- ai-review:openai -->\n"
    footer = (
        f"\n\n_Advisory review by `{model}` on `{sha}`. "
        "Observations only — not a merge verdict._\n"
    )
    write_review(header + review + footer)
    return 0


if __name__ == "__main__":
    sys.exit(main())
