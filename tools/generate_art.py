#!/usr/bin/env python3
"""Generate pixel art via PixelLab from per-asset `.spec.md` files.

Each spec is self-contained: YAML frontmatter (path, asset_type,
canvas dims) + a markdown body that describes the figure /
instrument / pose / background. The generator prepends a tight
asset-type lead-in (`SUBJECT_LEADS`) and sends only that + the body
to PixelLab — pixflux loses the plot on long composed prompts.

Usage:
    python tools/generate_art.py --spec assets/sprites/characters/guitar.spec.md
    python tools/generate_art.py --all
    python tools/generate_art.py --spec ... --dry-run

Backend: PixelLab `generate_image_pixflux` (synchronous, returns base64
PNG). Max image size is 400x400 px. Pro-mode multi-direction characters
are intentionally NOT used here — portraits are single south-facing
static images by design (see `docs/art.md`).

The endpoint is non-deterministic; re-running the same spec produces a
fresh take, not a byte-for-byte copy.
"""
from __future__ import annotations

import argparse
import base64
import sys
from pathlib import Path

# Local module — provides REPO_ROOT, env loading, spec parsing,
# inherits-chain rendering, .import sidecar writer, provenance writer.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _spec_loader import (  # noqa: E402
    REPO_ROOT,
    existing_uid,
    load_env,
    load_spec,
    write_png_import_sidecar,
    write_provenance,
)

import pixellab  # noqa: E402

SPRITES_DIR = REPO_ROOT / "assets" / "sprites"

# PixelLab pixflux endpoint hard limits.
PIXELLAB_BASE_URL = "https://api.pixellab.ai/v1"
PIXELLAB_BACKEND_NAME = "pixellab.generate_image_pixflux"
PIXFLUX_MAX_DIM = 400

# Quality knobs tuned to the 16-bit register in `docs/art.md`.
# Max-detail + max-shading produce PS1-2D gradient density that fights
# the SNES/Genesis brief (2–4 shading bands per surface). We keep
# prompt-adherence at the ceiling but pull detail+shading to mid-tier
# so the pixflux output reads as 16-bit hand-painted, not 2010s
# painted-pixel-art.
QUALITY_TEXT_GUIDANCE_SCALE = 20.0  # 1..20 (max prompt adherence)
QUALITY_DETAIL = "low detail"  # one of: low detail / medium detail / highly detailed
QUALITY_SHADING = "flat shading"  # flat / basic / medium / detailed / highly detailed shading
# Tarot-card register wants bold black linework (Rider-Waite). "lineless"
# was pulling toward painterly-pixel; swapping to single-color outline
# snaps into the flat-symbolic tarot register the aesthetic brief asks
# for.
QUALITY_OUTLINE = "single color black outline"

# Tight subject lead-ins per asset_type. Pixflux is a small-image
# generator and loses the plot under verbose composed prompts
# (empirically: 5500-char prompts produced vista-only scenes with no
# figure; same body with a 200-char subject-led prompt produced
# exactly the framed portrait we asked for). The lead-in carries the
# global aesthetic register; the per-spec body carries the figure /
# instrument / pose / background.
#
# Source-of-truth: this dict IS the prompt header that ships to the
# model. `docs/art.md` is the human-facing design reference — it
# describes the same aesthetic in fuller form for spec authors but
# is NOT concatenated into prompts. Keep the rules here in sync with
# `docs/art.md → Universal style` so designers and the model stay
# pointed at the same target.
SUBJECT_LEADS: dict[str, str] = {
    "character": (
        "Pixel art tarot card in the flat symbolic register of the RIDER-WAITE "
        "TAROT DECK. Flat 2-color fills per surface. Thick bold black outlines "
        "around every shape. No gradient shading, no realistic anatomy, no "
        "painted rendering. Symbolic, iconic, hieratic, flat. Warm-saturated "
        "palette (gold-yellow, chartreuse, moss-green, rose, coral). The "
        "figure, instrument, pose, and background described below are an "
        "EXAGGERATED archetype — render exactly as written. "
    ),
    "background": (
        "16-bit pixel art landscape background in the style of Heinz Edelmann Yellow "
        "Submarine journey vistas and Moebius (Jean Giraud) cosmic-threshold landscapes. "
        "Full-bleed scene, no border. A psychedelic vista at sunset / dream-hour / "
        "gold-hour, warm-saturated palette (gold-yellow, chartreuse, moss-green, rose, "
        "coral). 16-bit pixel register: limited shading bands, hand-painted pixels, "
        "soft dithering, anti-aliased curves. No text or letters in the image. "
    ),
    "band_card": (
        "Pixel art tarot card. The figure is rendered as a high-contrast SILHOUETTE — "
        "a flat dark-blue mass with NO facial features, NO clothing detail, NO inner "
        "lines on the body; only the readable outline shape. Monochromatic palette: "
        "every shape uses a shade of blue (deep navy, cobalt, mid-blue, pale ice-blue) "
        "and nothing else — no warm hues. Bold black outline around every shape. "
        "Tarot-card register: hieratic, symbolic, flat. The instrument and background "
        "described below also render in the same monochromatic-blue silhouette style. "
    ),
}


def render_for_image_gen(asset_type: str, body: str) -> str:
    """Compose the API prompt: short asset-type lead + spec body."""
    lead = SUBJECT_LEADS.get(asset_type)
    if lead is None:
        raise SystemExit(f"unknown asset_type {asset_type!r}; expected one of {list(SUBJECT_LEADS)}")
    return f"{lead}\n\n{body.strip()}\n"

REQUIRED_LOCAL_KEYS = ("path", "asset_type")

# Per-asset-type canvas defaults. Spec frontmatter overrides any of
# these on a per-asset basis, but the common case is "all characters
# share dims, all backgrounds share dims" — so the default belongs
# next to the asset_type's prompt lead-in, not duplicated in 12+
# spec files. Change `character.width` here to rescale every
# portrait in one place.
ASSET_TYPE_DEFAULTS: dict[str, dict] = {
    "character": {
        "width": 288,  # 3:4 Mona-Lisa proportion at full pixflux budget (max 400 per side).
        "height": 384,
        "no_background": False,
    },
    "background": {
        "width": 400,  # 16:9 at full pixflux budget; runtime upscales to 1280×720.
        "height": 225,
        "no_background": False,
    },
    "band_card": {
        "width": 288,  # match character portrait dims — same card size on screen.
        "height": 384,
        "no_background": False,
    },
}


def _validate_dims(spec_path: Path, width: int, height: int) -> None:
    if width < 16 or height < 16:
        raise SystemExit(f"{spec_path}: width/height must be >= 16, got {width}x{height}")
    if width > PIXFLUX_MAX_DIM or height > PIXFLUX_MAX_DIM:
        raise SystemExit(
            f"{spec_path}: width/height exceed pixflux max {PIXFLUX_MAX_DIM}, got {width}x{height}"
        )


def generate_one(
    spec_path: Path,
    *,
    dry_run: bool,
    env: dict[str, str],
) -> None:
    frontmatter, body = load_spec(spec_path, REQUIRED_LOCAL_KEYS)

    output_path = (REPO_ROOT / frontmatter["path"]).resolve()
    asset_type = frontmatter["asset_type"]
    defaults = ASSET_TYPE_DEFAULTS.get(asset_type, {})
    if "width" not in frontmatter and "width" not in defaults:
        raise SystemExit(
            f"{spec_path}: 'width' missing — provide it in spec frontmatter "
            f"or add a default for asset_type={asset_type!r} in ASSET_TYPE_DEFAULTS."
        )
    if "height" not in frontmatter and "height" not in defaults:
        raise SystemExit(
            f"{spec_path}: 'height' missing — provide it in spec frontmatter "
            f"or add a default for asset_type={asset_type!r} in ASSET_TYPE_DEFAULTS."
        )
    width = int(frontmatter.get("width", defaults.get("width")))
    height = int(frontmatter.get("height", defaults.get("height")))
    seed = int(frontmatter.get("seed", 0))
    no_background = bool(frontmatter.get("no_background", defaults.get("no_background", False)))

    _validate_dims(spec_path, width, height)

    rendered_api = render_for_image_gen(asset_type, body)

    rel_spec = spec_path.relative_to(REPO_ROOT).as_posix()
    rel_out = output_path.relative_to(REPO_ROOT).as_posix()
    print(
        f"\n=== {rel_spec} → {rel_out}  "
        f"({width}x{height}, asset_type={asset_type}, "
        f"seed={seed or 'random'}, api_prompt={len(rendered_api)} chars)"
    )

    if dry_run:
        print("\n--- API prompt (sent to PixelLab) ---")
        print(rendered_api)
        print("--- end ---")
        return

    secret = env.get("PIXELLAB_SECRET", "").strip()
    if not secret:
        raise SystemExit(
            "PIXELLAB_SECRET missing or empty. Add it to .env. "
            "Get a key from https://pixellab.ai/account."
        )

    client = pixellab.Client(secret=secret)
    print(
        f"  calling pixellab pixflux ({width}x{height}, "
        f"detail={QUALITY_DETAIL!r}, shading={QUALITY_SHADING!r}, "
        f"outline={QUALITY_OUTLINE!r}, guidance={QUALITY_TEXT_GUIDANCE_SCALE})..."
    )
    response = client.generate_image_pixflux(
        description=rendered_api,
        image_size={"width": width, "height": height},
        no_background=no_background,
        seed=seed,
        text_guidance_scale=QUALITY_TEXT_GUIDANCE_SCALE,
        detail=QUALITY_DETAIL,
        shading=QUALITY_SHADING,
        outline=QUALITY_OUTLINE,
    )

    png_bytes = base64.b64decode(response.image.base64)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(png_bytes)
    print(f"  wrote {rel_out}  ({len(png_bytes)} bytes)")

    preserved = existing_uid(output_path.with_suffix(output_path.suffix + ".import"))
    import_path = write_png_import_sidecar(output_path, preserved_uid=preserved)
    print(
        f"  wrote {import_path.relative_to(REPO_ROOT).as_posix()}  "
        f"(uid={'preserved' if preserved else 'will be minted on next import'})"
    )

    provenance_path = write_provenance(
        spec_path=spec_path,
        spec_frontmatter=frontmatter,
        output_path=output_path,
        extra_paths={"import_sidecar": import_path},
        rendered_prompt=rendered_api,
        backend_metadata={
            "name": PIXELLAB_BACKEND_NAME,
            "base_url": PIXELLAB_BASE_URL,
            "image_size": {"width": width, "height": height},
            "seed": seed,
            "no_background": no_background,
            "text_guidance_scale": QUALITY_TEXT_GUIDANCE_SCALE,
            "detail": QUALITY_DETAIL,
            "shading": QUALITY_SHADING,
            "outline": QUALITY_OUTLINE,
            "usage_usd": float(response.usage.usd),
        },
    )
    print(f"  wrote {provenance_path.relative_to(REPO_ROOT).as_posix()}")


def find_all_specs() -> list[Path]:
    """Walk SPRITES_DIR for *.spec.md, skipping leading-underscore non-targets."""
    specs: list[Path] = []
    for p in sorted(SPRITES_DIR.rglob("*.spec.md")):
        if p.name.startswith("_"):
            continue  # _-prefixed specs are non-generation (e.g. palette spec consumed elsewhere)
        specs.append(p)
    return specs


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate pixel art via PixelLab from .spec.md files."
    )
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--spec", help="Path to a single .spec.md file")
    target.add_argument(
        "--all",
        action="store_true",
        help=f"Regenerate every non-_ *.spec.md under {SPRITES_DIR.relative_to(REPO_ROOT).as_posix()}/",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the rendered prompt without calling PixelLab (no API cost).",
    )
    args = parser.parse_args()

    env = load_env()

    if args.spec:
        specs = [Path(args.spec).resolve()]
    else:
        specs = find_all_specs()
        if not specs:
            raise SystemExit(
                f"No *.spec.md files found under {SPRITES_DIR.relative_to(REPO_ROOT).as_posix()}/."
            )

    for spec in specs:
        generate_one(spec, dry_run=args.dry_run, env=env)


if __name__ == "__main__":
    main()
