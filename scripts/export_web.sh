#!/usr/bin/env bash
# Headless Godot 4.7.2 Web export into build/web.
# Commit that directory; .github/workflows/deploy-pages.yml publishes it to
# GitHub Pages. GitHub rejects any one file of 100 MiB or more, so heavy
# directories listed in export/packs.json are exported as extra .pck files.
# Cloudflare hosting is optional and still blocked by the 25 MiB file limit.
# Usage:
#   ./scripts/export_web.sh
#   GODOT_BIN=/path/to/godot ./scripts/export_web.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_VERSION="4.7.2"
PRESET_NAME="Web"
OUT_DIR="${ROOT}/build/web"
OUT_HTML="${OUT_DIR}/index.html"
HEADERS_SRC="${ROOT}/public/_headers"
GODOT_BIN="${GODOT_BIN:-godot}"

if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  DEFAULT_TEMPLATES="${XDG_DATA_HOME}/godot/export_templates/${GODOT_VERSION}.stable"
else
  DEFAULT_TEMPLATES="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
fi
TEMPLATE_DIR="${GODOT_EXPORT_TEMPLATES:-$DEFAULT_TEMPLATES}"
TEMPLATE_RELEASE="${TEMPLATE_DIR}/web_nothreads_release.zip"
TEMPLATE_DEBUG="${TEMPLATE_DIR}/web_nothreads_debug.zip"
TEMPLATE_ICU="${TEMPLATE_DIR}/icudt_godot.dat"

fail() {
  echo "error: $*" >&2
  exit 1
}

resolve_godot() {
  if [[ -x "$GODOT_BIN" ]]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi
  if command -v "$GODOT_BIN" >/dev/null 2>&1; then
    command -v "$GODOT_BIN"
    return 0
  fi
  return 1
}

if ! GODOT_PATH="$(resolve_godot)"; then
  fail "Godot binary not found (${GODOT_BIN}). Install Godot ${GODOT_VERSION} or set GODOT_BIN to the editor executable."
fi

VERSION="$("$GODOT_PATH" --version 2>&1 || true)"
VERSION="${VERSION%%$'\n'*}"
echo "Using Godot: ${GODOT_PATH}"
echo "Version: ${VERSION:-<no output>}"
if [[ "$VERSION" != *"${GODOT_VERSION}"* ]]; then
  fail "expected Godot ${GODOT_VERSION}, got: ${VERSION:-unknown}. This project matches Godot ${GODOT_VERSION} (project.godot features=4.7)."
fi

if [[ ! -f "$TEMPLATE_RELEASE" || ! -f "$TEMPLATE_DEBUG" || ! -f "$TEMPLATE_ICU" ]]; then
  cat >&2 <<EOF
error: Web export templates for Godot ${GODOT_VERSION} are missing.
Expected all of:
  ${TEMPLATE_RELEASE}
  ${TEMPLATE_DEBUG}
  ${TEMPLATE_ICU}

Threads are off, so use the nothreads zips (not web_release.zip / web_debug.zip).
--export-release reads web_nothreads_release.zip. Godot still checks
web_nothreads_debug.zip because the preset is runnable (editor play-in-browser).
icudt_godot.dat is the matching text data; without it, Traditional Chinese in
the web build can fall back to whatever ICU the editor binary embedded.

Download Godot_v${GODOT_VERSION}-stable_export_templates.tpz from
https://github.com/godotengine/godot/releases/tag/${GODOT_VERSION}-stable
and copy those files into:
  ${TEMPLATE_DIR}

Or set GODOT_EXPORT_TEMPLATES to the directory that already contains them.
Editor → Manage Export Templates installs the same folder.
EOF
  exit 1
fi

if [[ ! -f export_presets.cfg ]] || ! grep -q '^name="Web"$' export_presets.cfg; then
  fail "export preset \"${PRESET_NAME}\" not found in ${ROOT}/export_presets.cfg"
fi

if ! grep -q '^name="Web Pack"$' export_presets.cfg; then
  fail "export preset \"Web Pack\" not found in ${ROOT}/export_presets.cfg"
fi

echo "Checking resource-pack manifest"
python3 "${ROOT}/scripts/pack_manifest.py" check

if [[ ! -f "$HEADERS_SRC" ]]; then
  fail "missing ${HEADERS_SRC} (Cloudflare content types for .wasm, .pck, and .js)"
fi

mkdir -p "$OUT_DIR"
shopt -s nullglob
for item in "$OUT_DIR"/* "$OUT_DIR"/.[!.]* "$OUT_DIR"/..?*; do
  base="$(basename "$item")"
  if [[ "$base" == ".gitkeep" ]]; then
    continue
  fi
  rm -rf "$item"
done
shopt -u nullglob

echo "Importing project (first run creates .godot/)..."
if ! "$GODOT_PATH" --headless --path "$ROOT" --import; then
  fail "Godot import failed. If the log says the binary cannot start, install the editor's shared libraries (libX11, libGL, fontconfig)."
fi

echo "Exporting secondary resource packs"
while IFS=$'\t' read -r pack_id pack_file; do
  if [[ -z "${pack_id}" ]]; then
    continue
  fi
  pack_dest="${OUT_DIR}/${pack_file}"
  mkdir -p "$(dirname "$pack_dest")"
  echo "Exporting pack ${pack_id} -> ${pack_dest}"
  if ! RESOURCE_PACK_ROLE="${pack_id}" "$GODOT_PATH" --headless --path "$ROOT" --export-pack "Web Pack" "$pack_dest"; then
    fail "Godot --export-pack failed for ${pack_id}. The Web Pack preset and addons/resource_packs must be enabled."
  fi
done < <(python3 "${ROOT}/scripts/pack_manifest.py" list-packs)

echo "Exporting preset \"${PRESET_NAME}\" -> ${OUT_HTML}"
if ! RESOURCE_PACK_ROLE=main "$GODOT_PATH" --headless --path "$ROOT" --export-release "$PRESET_NAME" "$OUT_HTML"; then
  cat >&2 <<EOF
error: Godot export failed.
If the log mentions a missing template, install:
  ${TEMPLATE_RELEASE}
  ${TEMPLATE_DEBUG}
  ${TEMPLATE_ICU}
The Web preset keeps variant/thread_support=false, so the nothreads zips are required.
EOF
  exit 1
fi

missing=()
for required in index.html index.js index.wasm index.pck; do
  if [[ ! -f "${OUT_DIR}/${required}" ]]; then
    missing+=("$required")
  fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
  fail "export finished but build/web is incomplete (missing: ${missing[*]})"
fi

cp "$HEADERS_SRC" "${OUT_DIR}/_headers"
echo "Copied public/_headers -> build/web/_headers"

# Godot's Image.save_png rewrites index.png as a large truecolor file.
# Quantize it back so the Pages loading image stays near the source splash size.
SPLASH_PNG="${OUT_DIR}/index.png"
if [[ -f "$SPLASH_PNG" ]] && command -v pngquant >/dev/null 2>&1; then
  tmp_splash="${SPLASH_PNG}.quant.png"
  if pngquant --quality=90-100 --speed 1 --strip --force -o "$tmp_splash" "$SPLASH_PNG"; then
    mv "$tmp_splash" "$SPLASH_PNG"
    echo "Recompressed boot splash: ${SPLASH_PNG}"
  else
    rm -f "$tmp_splash"
    echo "pngquant left the boot splash unchanged"
  fi
fi
python3 "${ROOT}/scripts/pack_manifest.py" write-web "$OUT_DIR"
python3 "${ROOT}/scripts/pack_manifest.py" check-sizes "$OUT_DIR"
python3 "${ROOT}/scripts/pack_manifest.py" check-layout "$OUT_DIR"

echo "Opening secondary packs with Godot"
if ! "$GODOT_PATH" --headless --path "$ROOT" --script res://scripts/check_exported_packs.gd; then
  fail "Godot could not load one of the exported resource packs"
fi

echo "Web export ready: ${OUT_DIR}"
