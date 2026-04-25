#!/usr/bin/env python3
"""Generate a UI palette `.tres` from `_palette.spec.md` via the Claude API.

The palette is *not* pixel art — PixelLab is the wrong tool. We ask
Claude to derive named hex codes from the spec's body (which carries
the world / aesthetic context inline) and the slot list declared in
the frontmatter. Output is a Godot Resource (`PaletteDef`) at the
spec's `output:` path, so scenes can reference one source-of-truth
palette via the project Theme.

Usage:
    python tools/generate_palette.py --spec assets/sprites/_palette.spec.md
    python tools/generate_palette.py --spec ... --dry-run

Environment:
    ANTHROPIC_API_KEY in .env

Like the other generators, the API call is non-deterministic — re-runs
produce variation, not byte-for-byte stability. Provenance lives in
`<output-stem>.generated.json`.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _spec_loader import (  # noqa: E402
    REPO_ROOT,
    load_env,
    load_spec,
    write_provenance,
)

import anthropic  # noqa: E402

REQUIRED_KEYS = ("output", "asset_type", "slots")
DEFAULT_MODEL = "claude-sonnet-4-6"  # Sonnet handles aesthetic judgment well at a fraction of Opus cost; palette is light work. Override with --model.
MAX_TOKENS = 2048


SYSTEM_PROMPT = (
    "You are a pixel-art palette designer working inside a specific "
    "creative brief. You will be given world / aesthetic context, "
    "followed by a `--- spec ---` block describing a UI palette to "
    "produce. Your job: emit a single JSON object mapping each slot "
    "name from the spec to a hex color in `#RRGGBB` format. No alpha. "
    "Reply ONLY with a fenced ```json code block; no prose, no "
    "explanation, no comments inside the JSON. The palette must obey "
    "the brief: warm-weighted, impossibly saturated, no grey-brown, "
    "no desaturation. Background slots may be deep but must remain "
    "warm-toned. Treat each slot's name as a hint to its semantic role "
    "(bg, surface, text_primary, accent_warm, danger, etc.)."
)


def _hex_to_godot_color(hex_str: str) -> str:
    """`#RRGGBB` → `Color(r, g, b, 1)` literal, normalized to 0..1."""
    m = re.fullmatch(r"#?([0-9A-Fa-f]{6})", hex_str.strip())
    if not m:
        raise ValueError(f"invalid hex color: {hex_str!r}")
    h = m.group(1)
    r = int(h[0:2], 16) / 255.0
    g = int(h[2:4], 16) / 255.0
    b = int(h[4:6], 16) / 255.0
    return f"Color({r:.4f}, {g:.4f}, {b:.4f}, 1)"


def _existing_uid(tres_path: Path) -> str | None:
    if not tres_path.exists():
        return None
    m = re.search(r'uid="(uid://[^"]+)"', tres_path.read_text())
    return m.group(1) if m else None


def write_palette_tres(
    output_path: Path,
    *,
    slot_to_hex: dict[str, str],
    palette_script_path: str,
) -> None:
    """Write a Godot Resource `.tres` for the PaletteDef.

    Preserves the existing UID so any scene already referencing this
    palette by UID does not break across regen.
    """
    preserved_uid = _existing_uid(output_path)
    uid_attr = f' uid="{preserved_uid}"' if preserved_uid else ""

    body = [
        f'[gd_resource type="Resource" script_class="PaletteDef" load_steps=2 format=3{uid_attr}]',
        "",
        f'[ext_resource type="Script" path="{palette_script_path}" id="1_palette_script"]',
        "",
        "[resource]",
        'script = ExtResource("1_palette_script")',
    ]
    for slot, hex_color in slot_to_hex.items():
        body.append(f"{slot} = {_hex_to_godot_color(hex_color)}")
    body.append("")  # trailing newline
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(body))


def call_claude(api_key: str, prompt: str, model: str) -> tuple[str, dict]:
    """Single-shot Claude call. Returns (assistant_text, metadata)."""
    client = anthropic.Anthropic(api_key=api_key)
    msg = client.messages.create(
        model=model,
        max_tokens=MAX_TOKENS,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}],
    )
    text_blocks = [block.text for block in msg.content if getattr(block, "type", None) == "text"]
    text = "".join(text_blocks).strip()
    metadata = {
        "model": msg.model,
        "stop_reason": msg.stop_reason,
        "usage": {
            "input_tokens": msg.usage.input_tokens,
            "output_tokens": msg.usage.output_tokens,
        },
    }
    return text, metadata


def parse_palette_json(raw: str, expected_slots: list[str]) -> dict[str, str]:
    """Pull the JSON object out of a fenced code block and validate slots."""
    fence = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
    blob = fence.group(1) if fence else raw
    data = json.loads(blob)
    if not isinstance(data, dict):
        raise ValueError(f"expected JSON object, got {type(data).__name__}")
    missing = [s for s in expected_slots if s not in data]
    if missing:
        raise ValueError(f"palette response missing slots: {missing}")
    extra = [k for k in data if k not in expected_slots]
    if extra:
        raise ValueError(f"palette response has unexpected slots: {extra}")
    return {s: data[s] for s in expected_slots}


def generate_one(spec_path: Path, *, dry_run: bool, env: dict[str, str], model: str) -> None:
    frontmatter, body = load_spec(spec_path, REQUIRED_KEYS)
    output_path = (REPO_ROOT / frontmatter["output"]).resolve()
    slots: list[str] = list(frontmatter["slots"])

    rendered = body.strip() + "\n"
    rel_spec = spec_path.relative_to(REPO_ROOT).as_posix()
    rel_out = output_path.relative_to(REPO_ROOT).as_posix()
    print(
        f"\n=== {rel_spec} → {rel_out}  "
        f"({len(slots)} slots, prompt={len(rendered)} chars, model={model})"
    )

    if dry_run:
        print("\n--- rendered prompt ---")
        print(rendered)
        print("--- end prompt ---")
        return

    api_key = env.get("ANTHROPIC_API_KEY", "").strip()
    if not api_key:
        raise SystemExit(
            "ANTHROPIC_API_KEY missing or empty. Add it to .env. "
            "Get a key from https://console.anthropic.com/."
        )

    raw, metadata = call_claude(api_key, rendered, model)
    slot_to_hex = parse_palette_json(raw, slots)
    print("  derived palette:")
    for slot, hex_color in slot_to_hex.items():
        print(f"    {slot:18s} {hex_color}")

    palette_script_path = "res://scripts/data/palette_def.gd"
    write_palette_tres(
        output_path,
        slot_to_hex=slot_to_hex,
        palette_script_path=palette_script_path,
    )
    print(f"  wrote {rel_out}")

    provenance_path = write_provenance(
        spec_path=spec_path,
        spec_frontmatter=frontmatter,
        output_path=output_path,
        extra_paths={},
        rendered_prompt=rendered,
        backend_metadata={
            "name": "anthropic.messages",
            **metadata,
            "raw_response": raw,
            "palette": slot_to_hex,
        },
    )
    print(f"  wrote {provenance_path.relative_to(REPO_ROOT).as_posix()}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a UI palette .tres via the Claude API from a _palette.spec.md."
    )
    parser.add_argument("--spec", required=True, help="Path to the palette spec file")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the rendered prompt without calling the Claude API (no cost).",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Anthropic model id (default: {DEFAULT_MODEL}).",
    )
    args = parser.parse_args()

    env = load_env()
    spec = Path(args.spec).resolve()
    generate_one(spec, dry_run=args.dry_run, env=env, model=args.model)


if __name__ == "__main__":
    main()
