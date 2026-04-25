#!/usr/bin/env python3
"""Generate music tracks via ElevenLabs from per-track `.spec.md` files.

Reads `docs/music.md` for world context, parses a per-track spec
(YAML frontmatter + markdown body), renders the concatenated prompt,
calls the ElevenLabs music endpoint, writes the audio file plus a
Godot `.import` sidecar and a `.generated.json` provenance sibling.

Usage:
    python tools/generate_music.py --spec assets/audio/music/theme.spec.md
    python tools/generate_music.py --all
    python tools/generate_music.py --spec ... --dry-run

See `README.md` ("Generating music") and `docs/music.md` for the
world-context contract. The ElevenLabs endpoint is non-deterministic:
re-running the same spec produces a fresh take, not a byte-for-byte
copy.
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import re
import sys
from pathlib import Path

import requests
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = REPO_ROOT / ".env"
WORLD_CONTEXT_PATH = REPO_ROOT / "docs" / "music.md"
MUSIC_DIR = REPO_ROOT / "assets" / "audio" / "music"

ELEVENLABS_ENDPOINT = "https://api.elevenlabs.io/v1/music"
ELEVENLABS_OUTPUT_FORMAT = "mp3_44100_128"
ELEVENLABS_MODEL_ID = "music_v1"
ELEVENLABS_PROMPT_MAX_CHARS = 4100  # API hard limit on the `prompt` field
HTTP_TIMEOUT_SEC = 600  # ElevenLabs music gen can take minutes for longer tracks


def load_env(path: Path) -> dict[str, str]:
    """Tiny `.env` reader. KEY=VALUE per line, `#` comments, no expansion."""
    env: dict[str, str] = {}
    if not path.exists():
        return env
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        env[key.strip()] = value.strip().strip('"').strip("'")
    return env


def load_spec(spec_path: Path) -> tuple[dict, str]:
    """Parse a spec file. Returns (frontmatter dict, body string)."""
    text = spec_path.read_text()
    if not text.startswith("---"):
        raise ValueError(f"{spec_path}: missing YAML frontmatter (must start with '---')")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError(f"{spec_path}: malformed frontmatter (no closing '---')")
    frontmatter = yaml.safe_load(parts[1]) or {}
    body = parts[2].lstrip()
    for required in ("path", "loop", "length_sec", "instrumental"):
        if required not in frontmatter:
            raise ValueError(f"{spec_path}: frontmatter missing required key '{required}'")
    return frontmatter, body


def render_prompt(world_context: str, spec_body: str) -> str:
    """Concatenate world context + per-track spec body for ElevenLabs."""
    return f"{world_context.strip()}\n\n---\n\n{spec_body.strip()}\n"


def existing_uid(import_path: Path) -> str | None:
    """Pull the `uid=\"uid://...\"` line from an existing .import sidecar, if any."""
    if not import_path.exists():
        return None
    match = re.search(r'uid="(uid://[^"]+)"', import_path.read_text())
    return match.group(1) if match else None


def write_import_sidecar(audio_path: Path, *, loop: bool, preserved_uid: str | None) -> Path:
    """Write a Godot MP3 importer .import sidecar.

    Omits `path` / `dest_files` so Godot regenerates the cached imported binary
    on next editor open or headless --import. Preserves existing UID if present.
    """
    import_path = audio_path.with_suffix(audio_path.suffix + ".import")
    rel_source = audio_path.relative_to(REPO_ROOT).as_posix()
    uid_line = f'uid="{preserved_uid}"\n' if preserved_uid else ""
    body = (
        "[remap]\n"
        "\n"
        'importer="mp3"\n'
        'type="AudioStreamMP3"\n'
        f"{uid_line}"
        "\n"
        "[deps]\n"
        "\n"
        f'source_file="res://{rel_source}"\n'
        "\n"
        "[params]\n"
        "\n"
        f"loop={'true' if loop else 'false'}\n"
        "loop_offset=0\n"
        "bpm=0\n"
        "beat_count=0\n"
        "bar_beats=4\n"
    )
    import_path.write_text(body)
    return import_path


def write_provenance(
    *,
    spec_path: Path,
    spec_frontmatter: dict,
    audio_path: Path,
    import_sidecar_path: Path,
    rendered_prompt: str,
    length_ms: int,
) -> Path:
    """Write `<name>.generated.json` next to the audio file.

    Captures both sides of the in-project audio setup:
    the audio (sha256, bytes) and the import behavior (loop value,
    sidecar path), plus the full spec frontmatter so a future reader
    can reconstruct the authored intent without consulting the spec.
    """
    audio_bytes = audio_path.read_bytes()
    payload = {
        "spec_path": spec_path.relative_to(REPO_ROOT).as_posix(),
        "spec_frontmatter": spec_frontmatter,
        "audio_path": audio_path.relative_to(REPO_ROOT).as_posix(),
        "import_sidecar_path": import_sidecar_path.relative_to(REPO_ROOT).as_posix(),
        "rendered_prompt": rendered_prompt,
        "elevenlabs": {
            "endpoint": ELEVENLABS_ENDPOINT,
            "model_id": ELEVENLABS_MODEL_ID,
            "output_format": ELEVENLABS_OUTPUT_FORMAT,
            "music_length_ms": length_ms,
        },
        "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "audio_sha256": hashlib.sha256(audio_bytes).hexdigest(),
        "audio_bytes": len(audio_bytes),
    }
    out_path = audio_path.with_suffix(".generated.json")
    out_path.write_text(json.dumps(payload, indent=2) + "\n")
    return out_path


def call_elevenlabs(api_key: str, prompt: str, length_ms: int, *, force_instrumental: bool) -> bytes:
    """POST to ElevenLabs music endpoint, return raw audio bytes."""
    headers = {"Content-Type": "application/json", "xi-api-key": api_key}
    params = {"output_format": ELEVENLABS_OUTPUT_FORMAT}
    body = {
        "prompt": prompt,
        "model_id": ELEVENLABS_MODEL_ID,
        "music_length_ms": length_ms,
        "force_instrumental": force_instrumental,
    }
    resp = requests.post(
        ELEVENLABS_ENDPOINT, headers=headers, params=params, json=body, timeout=HTTP_TIMEOUT_SEC
    )
    if resp.status_code != 200:
        raise SystemExit(f"ElevenLabs error {resp.status_code}: {resp.text[:500]}")
    return resp.content


def generate_one(spec_path: Path, world_context: str, *, dry_run: bool, env: dict[str, str]) -> None:
    frontmatter, body = load_spec(spec_path)
    audio_path = (REPO_ROOT / frontmatter["path"]).resolve()
    length_sec = int(frontmatter["length_sec"])
    length_ms = length_sec * 1000
    loop = bool(frontmatter["loop"])
    force_instrumental = bool(frontmatter["instrumental"])

    rendered = render_prompt(world_context, body)

    rel_spec = spec_path.relative_to(REPO_ROOT).as_posix()
    rel_audio = audio_path.relative_to(REPO_ROOT).as_posix()
    print(
        f"\n=== {rel_spec} → {rel_audio}  ({length_sec}s, loop={loop}, "
        f"instrumental={force_instrumental}, prompt={len(rendered)} chars)"
    )

    if len(rendered) > ELEVENLABS_PROMPT_MAX_CHARS:
        raise SystemExit(
            f"Rendered prompt is {len(rendered)} chars, exceeds ElevenLabs limit of "
            f"{ELEVENLABS_PROMPT_MAX_CHARS}. Trim docs/music.md or {rel_spec}."
        )

    if dry_run:
        print("\n--- rendered prompt ---")
        print(rendered)
        print("--- end prompt ---")
        return

    api_key = env.get("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        raise SystemExit(
            "ELEVENLABS_API_KEY missing or empty. Copy .env.example to .env and paste your key. "
            "See README.md → 'Generating music' for setup."
        )

    audio_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"  calling ElevenLabs (length={length_ms}ms, model={ELEVENLABS_MODEL_ID})...")
    audio_bytes = call_elevenlabs(
        api_key, rendered, length_ms, force_instrumental=force_instrumental
    )
    audio_path.write_bytes(audio_bytes)
    print(f"  wrote {rel_audio}  ({len(audio_bytes)} bytes)")

    preserved = existing_uid(audio_path.with_suffix(audio_path.suffix + ".import"))
    import_path = write_import_sidecar(audio_path, loop=loop, preserved_uid=preserved)
    print(f"  wrote {import_path.relative_to(REPO_ROOT).as_posix()}  (loop={loop}, uid={'preserved' if preserved else 'will be minted on next import'})")

    provenance_path = write_provenance(
        spec_path=spec_path,
        spec_frontmatter=frontmatter,
        audio_path=audio_path,
        import_sidecar_path=import_path,
        rendered_prompt=rendered,
        length_ms=length_ms,
    )
    print(f"  wrote {provenance_path.relative_to(REPO_ROOT).as_posix()}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate music tracks via ElevenLabs from .spec.md files."
    )
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--spec", help="Path to a single .spec.md file")
    target.add_argument(
        "--all",
        action="store_true",
        help=f"Regenerate every *.spec.md under {MUSIC_DIR.relative_to(REPO_ROOT).as_posix()}/",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the rendered prompt without calling ElevenLabs (no API cost).",
    )
    args = parser.parse_args()

    if not WORLD_CONTEXT_PATH.exists():
        raise SystemExit(f"World context missing: {WORLD_CONTEXT_PATH}. Create docs/music.md first.")
    world_context = WORLD_CONTEXT_PATH.read_text()
    env = load_env(ENV_PATH)

    if args.spec:
        specs = [Path(args.spec).resolve()]
    else:
        specs = sorted(MUSIC_DIR.glob("*.spec.md"))
        if not specs:
            raise SystemExit(f"No *.spec.md files found under {MUSIC_DIR.relative_to(REPO_ROOT).as_posix()}/.")

    for spec in specs:
        generate_one(spec, world_context, dry_run=args.dry_run, env=env)


if __name__ == "__main__":
    main()
