#!/usr/bin/env python3
"""Check and publish the extra Godot resource packs listed in export/packs.json.

GitHub rejects a push when any single file is 100 MiB or larger. The Web export
keeps the main index.pck under that line by moving whole directories into
secondary .pck files. This script checks that the preset, the shell, and (after
export) the built files agree with the manifest.

Commands:
  check                 manifest, presets, and web shell (no Godot)
  list-packs            print "id<TAB>file" for scripts/export_web.sh
  write-web <build/web> write packs.json next to index.html, with byte sizes
  check-sizes <dir>     fail if any file is >= 100 MiB
  check-layout <dir>    fail if a probe is in the wrong pack
  self-test             parser and wildcard checks
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "export" / "packs.json"
PRESETS_PATH = ROOT / "export_presets.cfg"
SHELL_PATH = ROOT / "export" / "web_shell.html"

MAIN_PRESET = "Web"
PACK_PRESET = "Web Pack"
# Editor-only addon. It must not ship inside the game pack.
EXTRA_MAIN_EXCLUDES = ("addons/resource_packs/*",)
INCLUDE_REQUIRED = "export/packs.json"
# GitHub blocks files that are 100 MiB or larger (binary GiB, not decimal MB).
GITHUB_MAX_BYTES = 100 * 1024 * 1024
WARN_BYTES = 90 * 1024 * 1024

PACK_MAGIC = 0x43504447
PACK_DIR_ENCRYPTED = 1 << 0
PACK_REL_FILEBASE = 1 << 1


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_manifest(path: Path = MANIFEST_PATH) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {path}")
    except json.JSONDecodeError as exc:
        fail(f"{path} is not JSON: {exc}")
    if not isinstance(data, dict):
        fail(f"{path} must be an object")
    if data.get("version") != 1:
        fail(f"{path} version must be 1")
    packs = data.get("packs")
    if not isinstance(packs, list) or not packs:
        fail(f"{path} needs a non-empty packs array")
    seen: set[str] = set()
    files: set[str] = set()
    for entry in packs:
        if not isinstance(entry, dict):
            fail("each pack must be an object")
        pack_id = entry.get("id")
        rel = entry.get("file")
        includes = entry.get("include")
        probe = entry.get("probe")
        if not isinstance(pack_id, str) or not pack_id.replace("-", "").replace("_", "").isalnum():
            fail(f"pack id must be a short slug, got {pack_id!r}")
        if pack_id in seen:
            fail(f"duplicate pack id {pack_id}")
        seen.add(pack_id)
        if pack_id == "main":
            fail("pack id 'main' is reserved for the primary Web export")
        if not isinstance(rel, str) or not _safe_rel(rel) or not rel.endswith(".pck"):
            fail(f"{pack_id}: file must be a relative .pck path, got {rel!r}")
        if rel in files:
            fail(f"duplicate pack file {rel}")
        files.add(rel)
        if not isinstance(includes, list) or not includes:
            fail(f"{pack_id}: include must be a non-empty list of res:// prefixes")
        for prefix in includes:
            if not isinstance(prefix, str) or not prefix.startswith("res://"):
                fail(f"{pack_id}: include prefix must start with res:// ({prefix!r})")
            folder = ROOT / prefix.removeprefix("res://").split("*", 1)[0].rstrip("/")
            if not folder.is_dir():
                fail(f"{pack_id}: include directory does not exist: {folder}")
        if not isinstance(probe, str) or not probe.startswith("res://"):
            fail(f"{pack_id}: probe must be a res:// file")
        probe_path = ROOT / probe.removeprefix("res://")
        if not probe_path.is_file():
            fail(f"{pack_id}: probe file does not exist: {probe_path}")
        if not _owned_by_includes(probe, includes):
            fail(f"{pack_id}: probe {probe} is outside include")
    return data


def _safe_rel(rel: str) -> bool:
    if not rel or rel.startswith("/") or "\\" in rel or "://" in rel:
        return False
    parts = Path(rel).parts
    return ".." not in parts


def _owned_by_includes(res_path: str, includes: list[str]) -> bool:
    norm = res_path.replace("\\", "/")
    for prefix in includes:
        pattern = prefix.replace("\\", "/")
        if pattern.endswith("*"):
            pattern = pattern[: pattern.rfind("*")]
        if pattern.endswith("/"):
            if norm.startswith(pattern):
                return True
        elif norm == pattern or norm.startswith(pattern + "/"):
            return True
    return False


def exclude_pattern_for_prefix(prefix: str) -> str:
    """Godot include/exclude filters match with and without the res:// prefix."""
    pattern = prefix.replace("\\", "/")
    if pattern.startswith("res://"):
        pattern = pattern[len("res://") :]
    pattern = pattern.lstrip("/")
    if pattern.endswith("*"):
        return pattern
    if not pattern.endswith("/"):
        pattern += "/"
    return pattern + "*"


def wildcard_match(text: str, pattern: str, case_sensitive: bool = False) -> bool:
    """Godot String.matchn: '*' is any run of characters, '?' is one non-dot."""
    if not text or not pattern:
        return False

    def rec(pi: int, ti: int) -> bool:
        if pi == len(pattern):
            return ti == len(text)
        char = pattern[pi]
        if char == "*":
            if rec(pi + 1, ti):
                return True
            return ti < len(text) and rec(pi, ti + 1)
        if ti >= len(text):
            return False
        if char == "?":
            return text[ti] != "." and rec(pi + 1, ti + 1)
        left = text[ti]
        right = char
        if not case_sensitive:
            left = left.upper()
            right = right.upper()
        return left == right and rec(pi + 1, ti + 1)

    return rec(0, 0)


def parse_presets(path: Path = PRESETS_PATH) -> dict[str, dict[str, str]]:
    if not path.is_file():
        fail(f"missing {path}")
    sections: dict[str, dict[str, str]] = {}
    current: str | None = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
            sections.setdefault(current, {})
            continue
        if current is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        sections[current][key.strip()] = value.strip()
    return sections


def _unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1]
    return value


def preset_by_name(sections: dict[str, dict[str, str]], name: str) -> tuple[str, dict[str, str], dict[str, str]]:
    found: list[tuple[str, dict[str, str]]] = []
    for section, values in sections.items():
        if section.count(".") != 1:
            continue
        if _unquote(values.get("name", "")) == name:
            found.append((section, values))
    if len(found) != 1:
        fail(f"expected exactly one export preset named {name!r}, found {len(found)}")
    section, values = found[0]
    options = sections.get(section + ".options", {})
    return section, values, options


def _filter_items(raw: str) -> list[str]:
    return [part.strip() for part in _unquote(raw).split(",") if part.strip()]


def check_presets(manifest: dict) -> None:
    sections = parse_presets()
    _section, main, main_opts = preset_by_name(sections, MAIN_PRESET)
    _pack_section, pack, pack_opts = preset_by_name(sections, PACK_PRESET)
    if _unquote(main.get("platform", "")) != "Web" or _unquote(pack.get("platform", "")) != "Web":
        fail("Web and Web Pack presets must use platform Web (same texture import)")
    if _unquote(main.get("export_filter", "")) != "all_resources":
        fail(f"{MAIN_PRESET} export_filter must stay all_resources")
    if _unquote(pack.get("export_filter", "")) != "all_resources":
        fail(f"{PACK_PRESET} export_filter must stay all_resources")
    include = _filter_items(main.get("include_filter", ""))
    if INCLUDE_REQUIRED not in include:
        fail(f"{MAIN_PRESET} include_filter must contain {INCLUDE_REQUIRED}")
    excludes = _filter_items(main.get("exclude_filter", ""))
    for extra in EXTRA_MAIN_EXCLUDES:
        if extra not in excludes:
            fail(f"{MAIN_PRESET} exclude_filter must contain {extra}")
    for entry in manifest["packs"]:
        for prefix in entry["include"]:
            sample = prefix.removeprefix("res://").rstrip("/").rstrip("*") + "/__sample__.png"
            sample = sample.replace("//", "/")
            if not any(wildcard_match(sample, item) or wildcard_match("res://" + sample, item) for item in excludes):
                pattern = exclude_pattern_for_prefix(prefix)
                fail(
                    f"{MAIN_PRESET} exclude_filter does not cover {prefix}. "
                    f"Add {pattern} (pack {entry['id']})."
                )
    role = _unquote(main_opts.get("resource_packs/role", ""))
    if role != "main":
        fail(f'{MAIN_PRESET} options need resource_packs/role="main"')
    pack_role = _unquote(pack_opts.get("resource_packs/role", ""))
    if pack_role == "main":
        fail(f'{PACK_PRESET} resource_packs/role must not be "main"')
    if _unquote(pack.get("runnable", "false")) == "true":
        fail(f"{PACK_PRESET} must not be runnable; only {MAIN_PRESET} is the game export")


def check_shell() -> None:
    if not SHELL_PATH.is_file():
        fail(f"missing {SHELL_PATH}")
    text = SHELL_PATH.read_text(encoding="utf-8")
    for needle in ("packs.json", "preloadFile", "preloadExtraPacks"):
        if needle not in text:
            fail(f"{SHELL_PATH.name} is missing {needle}")
    if "<base" in text.lower():
        fail("web shell must not set <base href>; Pages uses a trailing-slash redirect")
    if "/game-across-time/" in text:
        fail("web shell must keep pack URLs relative, not hard-code /game-across-time/")


def check() -> None:
    manifest = load_manifest()
    check_presets(manifest)
    check_shell()
    print(f"[packs] manifest OK ({len(manifest['packs'])} pack(s))")


def list_packs() -> None:
    manifest = load_manifest()
    for entry in manifest["packs"]:
        print(f"{entry['id']}\t{entry['file']}")


def list_pck_paths(path: Path) -> list[str]:
    data = path.read_bytes()
    if len(data) < 40 or struct.unpack_from("<I", data, 0)[0] != PACK_MAGIC:
        fail(f"{path} is not a Godot PCK")
    version = struct.unpack_from("<I", data, 4)[0]
    flags = struct.unpack_from("<I", data, 20)[0]
    if flags & PACK_DIR_ENCRYPTED:
        fail(f"{path} has an encrypted directory; this check only reads plain packs")
    if version in (3, 4):
        dir_offset = struct.unpack_from("<Q", data, 32)[0]
    elif version == 2:
        # Godot 4.7 still accepts V2: flags + file base, then 16 reserved uint32s.
        dir_offset = 32 + 16 * 4
    else:
        fail(f"{path} pack version {version} is not 2, 3, or 4")
    if dir_offset + 4 > len(data):
        fail(f"{path} directory offset {dir_offset} is past end of file")
    count = struct.unpack_from("<I", data, dir_offset)[0]
    pos = dir_offset + 4
    paths: list[str] = []
    for _ in range(count):
        if pos + 4 > len(data):
            fail(f"{path} directory truncated")
        length = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        if length < 0 or pos + length > len(data):
            fail(f"{path} directory entry length {length} is invalid")
        raw = data[pos : pos + length].rstrip(b"\x00")
        pos += length
        try:
            paths.append(raw.decode("utf-8"))
        except UnicodeDecodeError:
            fail(f"{path} has a non-utf8 pack path")
        pos += 8 + 8 + 16 + 4
    if flags & PACK_REL_FILEBASE or version >= 3:
        return paths
    return paths


def _norm(res_path: str) -> str:
    path = res_path.replace("\\", "/")
    if path.startswith("res://"):
        path = path[len("res://") :]
    return path.lstrip("/")


def write_web(build_dir: Path) -> None:
    manifest = load_manifest()
    published = json.loads(json.dumps(manifest))
    for entry in published["packs"]:
        pck = build_dir / entry["file"]
        if not pck.is_file():
            fail(f"missing exported pack {pck}")
        entry["bytes"] = pck.stat().st_size
    dest = build_dir / "packs.json"
    dest.write_text(json.dumps(published, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[packs] wrote {dest}")


def check_sizes(directory: Path) -> None:
    if not directory.is_dir():
        fail(f"missing {directory}")
    too_big: list[str] = []
    for path in sorted(directory.rglob("*")):
        if not path.is_file():
            continue
        size = path.stat().st_size
        rel = path.relative_to(directory)
        mib = size / (1024 * 1024)
        if size >= GITHUB_MAX_BYTES:
            too_big.append(f"{rel} is {mib:.2f} MiB")
        elif size >= WARN_BYTES:
            print(f"warning: {rel} is {mib:.2f} MiB (limit is 100 MiB)")
        else:
            print(f"[packs] {rel}: {mib:.2f} MiB")
    if too_big:
        fail("GitHub rejects files of 100 MiB or more:\n  " + "\n  ".join(too_big))


def _has_resource(paths: set[str], probe: str) -> bool:
    """Imported textures are stored as source.import plus a .ctex, not the raw file."""
    norm = _norm(probe)
    base = Path(norm).name
    if norm in paths or f"{norm}.import" in paths:
        return True
    return any(item.endswith(".ctex") and f"/{base}-" in f"/{item}" for item in paths)


def check_layout(build_dir: Path) -> None:
    manifest = load_manifest()
    main_pck = build_dir / "index.pck"
    if not main_pck.is_file():
        fail(f"missing {main_pck}")
    main_paths = set(list_pck_paths(main_pck))
    main_norm = {_norm(item) for item in main_paths}
    if "export/packs.json" not in main_norm:
        fail("index.pck does not contain export/packs.json (include_filter)")
    if "assets/boot_splash.png" not in main_norm:
        fail("index.pck is missing assets/boot_splash.png")
    web_manifest = build_dir / "packs.json"
    if not web_manifest.is_file():
        fail(f"missing {web_manifest}; run write-web first")
    published = json.loads(web_manifest.read_text(encoding="utf-8"))
    published_files = [entry.get("file") for entry in published.get("packs", [])]
    source_files = [entry["file"] for entry in manifest["packs"]]
    if published_files != source_files:
        fail(f"build packs.json files {published_files} != manifest {source_files}")
    for entry in manifest["packs"]:
        pck = build_dir / entry["file"]
        paths = {_norm(item) for item in list_pck_paths(pck)}
        probe = _norm(entry["probe"])
        if not _has_resource(paths, probe):
            fail(f"{entry['file']} does not contain imported {probe}")
        if _has_resource(main_norm, probe):
            fail(f"index.pck still contains {probe}; main export did not exclude this pack")
        if "export/packs.json" in paths:
            fail(f"{entry['file']} contains the manifest; that file stays in the main pack")
        if "scripts/game_state.gdc" in paths or "scripts/game_state.gd" in paths:
            fail(
                f"{entry['file']} contains game scripts. The export plugin must run before "
                "the GDScript exporter (plugin name sorts first) so skip() drops them."
            )
        print(f"[packs] {entry['id']}: {len(paths)} files, probe {probe} only in {entry['file']}")
    print("[packs] layout OK")


def self_test() -> None:
    assert wildcard_match("assets/family/a.png", "assets/family/*")
    assert wildcard_match("assets/family/nested/a.png", "assets/family/*")
    assert not wildcard_match("assets/family_other/a.png", "assets/family/*")
    assert wildcard_match("addons/resource_packs/plugin.gd", "addons/resource_packs/*")
    assert exclude_pattern_for_prefix("res://assets/family/") == "assets/family/*"
    blob = _sample_pck(["assets/family/daughter_early.png", "res-not-used.txt"])
    # write via a temp list function on bytes
    paths = _parse_bytes(blob)
    assert paths == ["assets/family/daughter_early.png", "res-not-used.txt"], paths
    print("[packs] self-test OK")


def _sample_pck(paths: list[str]) -> bytes:
    dir_offset = 104
    header = struct.pack("<IIIIII", PACK_MAGIC, 4, 4, 7, 2, PACK_REL_FILEBASE)
    header += struct.pack("<QQ", 0, dir_offset)
    header += b"\x00" * 64
    assert len(header) == dir_offset
    directory = bytearray(struct.pack("<I", len(paths)))
    for item in paths:
        raw = item.encode("utf-8")
        pad = (4 - (len(raw) % 4)) % 4
        directory += struct.pack("<I", len(raw) + pad)
        directory += raw + b"\x00" * pad
        directory += struct.pack("<QQ", 0, 0)
        directory += b"\x00" * 16
        directory += struct.pack("<I", 0)
    return header + bytes(directory)


def _parse_bytes(data: bytes) -> list[str]:
    tmp = Path("/tmp/pack-manifest-self-test.pck")
    tmp.write_bytes(data)
    try:
        return list_pck_paths(tmp)
    finally:
        tmp.unlink(missing_ok=True)


def main(argv: list[str]) -> None:
    if len(argv) < 2:
        fail("usage: pack_manifest.py check|list-packs|write-web|check-sizes|check-layout|self-test")
    command = argv[1]
    if command == "check":
        check()
    elif command == "list-packs":
        list_packs()
    elif command == "write-web":
        if len(argv) != 3:
            fail("usage: pack_manifest.py write-web build/web")
        write_web(Path(argv[2]))
    elif command == "check-sizes":
        if len(argv) != 3:
            fail("usage: pack_manifest.py check-sizes build/web")
        check_sizes(Path(argv[2]))
    elif command == "check-layout":
        if len(argv) != 3:
            fail("usage: pack_manifest.py check-layout build/web")
        check_layout(Path(argv[2]))
    elif command == "self-test":
        self_test()
    else:
        fail(f"unknown command {command}")


if __name__ == "__main__":
    main(sys.argv)
