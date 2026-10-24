#!/usr/bin/env python3
"""Build distinct album stills: daughter alone, or daughter with both parents.

Background plates live in art_src/album_bg/ (Godot ignores that folder).
Each output is one res://assets/album file. The same plate may be reused
only as a backdrop; the saved photo is a different file per theme and age band.
A second travel visit in the same band gets an evening, mirrored variant.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parent.parent
BG_DIR = ROOT / "art_src" / "album_bg"
FAMILY = ROOT / "assets" / "family"
OUT_DIR = ROOT / "assets" / "album"
CATALOG = OUT_DIR / "catalog.json"

W, H = 960, 720
BANDS = ("early", "elementary", "junior", "senior", "adult")

# Solo activities: only the daughter. Family activities: daughter, mother, father.
THEMES: list[tuple[str, str, tuple[str, ...]]] = [
    ("arts", "daughter", ("early", "elementary", "junior", "senior")),
    ("cafe", "daughter", ("senior",)),
    ("friends", "daughter", ("early", "elementary", "junior", "senior", "adult")),
    ("daytrip", "family", ("elementary", "junior", "senior", "adult")),
    ("library", "daughter", ("elementary", "junior", "senior")),
    ("festival", "daughter", ("early", "elementary", "junior", "senior", "adult")),
    ("elder", "family", ("early", "elementary", "junior", "senior", "adult")),
    ("perform", "daughter", ("elementary", "junior", "senior", "adult")),
    ("reading", "daughter", ("elementary", "junior", "senior", "adult")),
    ("market", "family", ("early", "elementary", "junior", "senior", "adult")),
    ("piano", "daughter", ("junior", "senior")),
    ("showcase", "daughter", ("junior", "senior")),
    ("date", "daughter", ("adult",)),
    ("homemeal", "family", ("adult",)),
    ("beach", "family", ("early", "elementary", "junior", "senior", "adult")),
    ("mountain", "family", ("early", "elementary", "junior", "senior", "adult")),
]

DESTINATIONS = ("china", "japan", "asia", "europe", "australia")
TRAVEL_BANDS = ("early", "elementary", "junior", "senior")
TRAVEL_ALT_BANDS = ("elementary", "senior")

# How tall the daughter is, as a fraction of the frame. Parents stay a step taller
# until she is grown.
SOLO_H = {
    "early": 0.72,
    "elementary": 0.78,
    "junior": 0.84,
    "senior": 0.90,
    "adult": 0.92,
}
FAMILY_H = {
    "early": (0.56, 0.84),
    "elementary": (0.64, 0.86),
    "junior": (0.74, 0.88),
    "senior": (0.84, 0.88),
    "adult": (0.90, 0.86),
}
# A slight time-of-day shift so two bands on one plate are not the same crop.
BAND_GRADE = {
    "early": (1.04, 1.02, 0.98),
    "elementary": (1.0, 1.0, 1.0),
    "junior": (0.98, 1.0, 1.04),
    "senior": (1.05, 1.0, 0.94),
    "adult": (0.96, 0.97, 1.0),
}

_CUTOUTS: dict[str, Image.Image] = {}


def cutout(path: Path) -> Image.Image:
    key = str(path)
    if key not in _CUTOUTS:
        im = Image.open(path).convert("RGBA")
        box = im.getbbox()
        if box:
            im = im.crop(box)
        _CUTOUTS[key] = im
    return _CUTOUTS[key]


def cover(im: Image.Image, w: int, h: int) -> Image.Image:
    im = im.convert("RGB")
    scale = max(w / im.width, h / im.height)
    nw = int(im.width * scale) + 1
    nh = int(im.height * scale) + 1
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return im.crop((left, top, left + w, top + h))


def grade(im: Image.Image, rgb: tuple[float, float, float]) -> Image.Image:
    r, g, b = im.split()
    r = r.point(lambda v, m=rgb[0]: min(255, int(v * m)))
    g = g.point(lambda v, m=rgb[1]: min(255, int(v * m)))
    b = b.point(lambda v, m=rgb[2]: min(255, int(v * m)))
    return Image.merge("RGB", (r, g, b))


def vignette(im: Image.Image) -> Image.Image:
    small = Image.new("L", (64, 48))
    px = small.load()
    for y in range(48):
        for x in range(64):
            dx = (x - 31.5) / 32.0
            dy = (y - 23.5) / 24.0
            d = (dx * dx + dy * dy) ** 0.5
            px[x, y] = max(0, min(255, int((d - 0.55) * 340)))
    mask = small.resize(im.size, Image.Resampling.BICUBIC)
    shade = Image.new("RGB", im.size, (48, 32, 40))
    return Image.composite(shade, im, mask)


def load_plate(name: str, band: str, alt: bool) -> Image.Image:
    path = BG_DIR / f"{name}.jpg"
    if not path.is_file():
        raise SystemExit(f"missing background plate {path}")
    im = cover(Image.open(path), W, H)
    # Soften distant detail (and any stray far-off mark) so the people read first.
    blur = 7 if name == "japan" else 2.4
    im = im.filter(ImageFilter.GaussianBlur(radius=blur))
    im = grade(im, BAND_GRADE[band])
    if alt:
        warm = Image.new("RGB", im.size, (255, 168, 102))
        im = Image.blend(im, warm, 0.22)
        im = ImageEnhance.Brightness(im).enhance(0.88)
    return im


def scale_h(im: Image.Image, height: int) -> Image.Image:
    height = max(80, int(height))
    width = max(40, int(im.width * height / im.height))
    return im.resize((width, height), Image.Resampling.LANCZOS)


def paste_feet(canvas: Image.Image, sprite: Image.Image, cx: int, foot_y: int) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sw = max(24, int(sprite.width * 0.55))
    sh = 22
    blob = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    bp = blob.load()
    for y in range(sh):
        for x in range(sw):
            dx = (x - sw / 2) / (sw / 2)
            dy = (y - sh / 2) / (sh / 2)
            if dx * dx + dy * dy <= 1:
                bp[x, y] = (40, 24, 32, 110)
    blob = blob.filter(ImageFilter.GaussianBlur(radius=6))
    shadow.alpha_composite(blob, (cx - sw // 2, foot_y - sh // 2))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(sprite, (cx - sprite.width // 2, foot_y - sprite.height))


def people(subject: str, band: str, alt: bool) -> list[Image.Image]:
    daughter = scale_h(cutout(FAMILY / f"daughter_{band}.png"), int(H * (FAMILY_H[band][0] if subject == "family" else SOLO_H[band])))
    if subject == "daughter":
        return [daughter]
    mom_h, dad_h = FAMILY_H[band][1], FAMILY_H[band][1]
    mom = scale_h(cutout(FAMILY / f"mom_{band}_cutout.png"), int(H * mom_h))
    dad = scale_h(cutout(FAMILY / f"dad_{band}.png"), int(H * dad_h))
    return [mom, daughter, dad]


def compose(plate_name: str, subject: str, band: str, alt: bool) -> Image.Image:
    base = load_plate(plate_name, band, alt).convert("RGBA")
    sprites = people(subject, band, alt)
    foot = H - 6
    gap = -int(min(s.width for s in sprites) * (0.06 if not alt else 0.02))
    total = sum(s.width for s in sprites) + gap * (len(sprites) - 1)
    x = (W - total) // 2
    shift = {"early": -18, "elementary": 0, "junior": 16, "senior": -12, "adult": 22}[band]
    if alt:
        shift = -shift
    x += shift
    for sprite in sprites:
        paste_feet(base, sprite, x + sprite.width // 2, foot)
        x += sprite.width + gap
    out = vignette(base.convert("RGB"))
    # One mirror of the finished frame: the evening plate and the flipped
    # grouping are a second photograph, not a second copy of the daylight one.
    if alt:
        out = ImageOps.mirror(out)
    return out


def jobs() -> list[dict]:
    rows: list[dict] = []
    for theme, subject, bands in THEMES:
        for band in bands:
            rows.append({
                "file": f"{theme}_{band}.jpg",
                "plate": theme,
                "subject": subject,
                "theme": theme,
                "band": band,
                "alt": False,
            })
    for dest in DESTINATIONS:
        theme = f"travel_{dest}"
        for band in TRAVEL_BANDS:
            rows.append({
                "file": f"travel_{dest}_{band}.jpg",
                "plate": dest,
                "subject": "family",
                "theme": theme,
                "band": band,
                "alt": False,
            })
        for band in TRAVEL_ALT_BANDS:
            rows.append({
                "file": f"travel_{dest}_{band}_b.jpg",
                "plate": dest,
                "subject": "family",
                "theme": theme,
                "band": band,
                "alt": True,
            })
    return rows


def main() -> None:
    only = set()
    if len(sys.argv) > 1:
        only = {part.strip() for part in sys.argv[1].split(",") if part.strip()}
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    photos = []
    hashes: dict[str, str] = {}
    for row in jobs():
        rel = f"res://assets/album/{row['file']}"
        photos.append({
            "path": rel,
            "subject": row["subject"],
            "theme": row["theme"],
            "band": row["band"],
            "alt": row["alt"],
        })
        if only and row["file"] not in only:
            continue
        im = compose(row["plate"], row["subject"], row["band"], row["alt"])
        dest = OUT_DIR / row["file"]
        im.save(dest, "JPEG", quality=86, optimize=True, progressive=True)
        digest = hashlib.sha256(dest.read_bytes()).hexdigest()
        if digest in hashes:
            raise SystemExit(f"duplicate bytes {row['file']} == {hashes[digest]}")
        hashes[digest] = row["file"]
        print(f"{dest.name:40} {dest.stat().st_size // 1024:4} KiB")
    if not only:
        CATALOG.write_text(json.dumps({"photos": photos}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"catalog {len(photos)} photos")


if __name__ == "__main__":
    main()
