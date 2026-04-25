"""Shared spec-loading utilities for `tools/generate_*.py`.

Both `generate_music.py` and `generate_art.py` (and `generate_palette.py`)
parse the same YAML-frontmatter-plus-markdown-body spec format. They also
share the `.import` sidecar pattern (preserve UID, omit cached fields so
Godot regenerates them on next `--import`) and the `<name>.generated.json`
provenance pattern.

Keep this module narrow: pure file IO + parsing. No HTTP, no model SDKs,
no asset-type-specific logic. Each generator brings its own API client
and provenance shape.
"""
from __future__ import annotations

import datetime
import hashlib
import json
import re
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = REPO_ROOT / ".env"


def load_env(path: Path = ENV_PATH) -> dict[str, str]:
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


def load_spec(spec_path: Path, required_keys: tuple[str, ...]) -> tuple[dict, str]:
    """Parse a spec file into (frontmatter dict, body string).

    Validates that every key in `required_keys` is present in the
    frontmatter. Raises ValueError with the spec path on failure so
    misauthored specs fail loudly at the call site.
    """
    text = spec_path.read_text()
    if not text.startswith("---"):
        raise ValueError(f"{spec_path}: missing YAML frontmatter (must start with '---')")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError(f"{spec_path}: malformed frontmatter (no closing '---')")
    frontmatter = yaml.safe_load(parts[1]) or {}
    body = parts[2].lstrip()
    for required in required_keys:
        if required not in frontmatter:
            raise ValueError(f"{spec_path}: frontmatter missing required key '{required}'")
    return frontmatter, body


def existing_uid(import_path: Path) -> str | None:
    """Pull `uid="uid://..."` from an existing .import sidecar, if any."""
    if not import_path.exists():
        return None
    match = re.search(r'uid="(uid://[^"]+)"', import_path.read_text())
    return match.group(1) if match else None


def write_png_import_sidecar(png_path: Path, *, preserved_uid: str | None) -> Path:
    """Write a Godot texture importer .import sidecar for a PNG.

    Omits `path` / `dest_files` / cached hash so Godot regenerates the
    cached imported binary on next editor open or headless `--import`.
    Preserves an existing UID if one is supplied so scene references
    don't break across regen.

    Pixel-art friendly defaults: lossless compression, no mipmaps,
    fix alpha border on, no 3D detection.
    """
    import_path = png_path.with_suffix(png_path.suffix + ".import")
    rel_source = png_path.relative_to(REPO_ROOT).as_posix()
    uid_line = f'uid="{preserved_uid}"\n' if preserved_uid else ""
    body = (
        "[remap]\n"
        "\n"
        'importer="texture"\n'
        'type="CompressedTexture2D"\n'
        f"{uid_line}"
        "\n"
        "[deps]\n"
        "\n"
        f'source_file="res://{rel_source}"\n'
        "\n"
        "[params]\n"
        "\n"
        "compress/mode=0\n"
        "compress/high_quality=false\n"
        "compress/lossy_quality=0.7\n"
        "compress/uastc_level=0\n"
        "compress/rdo_quality_loss=0.0\n"
        "compress/hdr_compression=1\n"
        "compress/normal_map=0\n"
        "compress/channel_pack=0\n"
        "mipmaps/generate=false\n"
        "mipmaps/limit=-1\n"
        "roughness/mode=0\n"
        'roughness/src_normal=""\n'
        "process/channel_remap/red=0\n"
        "process/channel_remap/green=1\n"
        "process/channel_remap/blue=2\n"
        "process/channel_remap/alpha=3\n"
        "process/fix_alpha_border=true\n"
        "process/premult_alpha=false\n"
        "process/normal_map_invert_y=false\n"
        "process/hdr_as_srgb=false\n"
        "process/hdr_clamp_exposure=false\n"
        "process/size_limit=0\n"
        "detect_3d/compress_to=1\n"
    )
    import_path.write_text(body)
    return import_path


def write_provenance(
    *,
    spec_path: Path,
    spec_frontmatter: dict,
    output_path: Path,
    extra_paths: dict[str, Path],
    rendered_prompt: str,
    backend_metadata: dict[str, Any],
) -> Path:
    """Write `<output-stem>.generated.json` next to the output file.

    Captures: spec inputs (path + full frontmatter for reconstruction),
    output paths (main file + any sidecars), the fully-rendered prompt
    (so a future regen can diff what changed), backend metadata (model,
    endpoint, etc.), generation timestamp, and the output's SHA256 +
    bytes for content-addressed comparison across regen runs.
    """
    output_bytes = output_path.read_bytes()
    payload: dict[str, Any] = {
        "spec_path": spec_path.relative_to(REPO_ROOT).as_posix(),
        "spec_frontmatter": spec_frontmatter,
        "output_path": output_path.relative_to(REPO_ROOT).as_posix(),
        "extra_paths": {k: v.relative_to(REPO_ROOT).as_posix() for k, v in extra_paths.items()},
        "rendered_prompt": rendered_prompt,
        "backend": backend_metadata,
        "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "output_sha256": hashlib.sha256(output_bytes).hexdigest(),
        "output_bytes": len(output_bytes),
    }
    out_path = output_path.with_suffix(".generated.json")
    out_path.write_text(json.dumps(payload, indent=2) + "\n")
    return out_path
