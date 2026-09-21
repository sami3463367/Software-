#!/usr/bin/env python3
"""Builds build/MossAndEmber.html — the whole game as one offline HTML file.

The engine (wasm + worklets), every game file and the boot script are inlined
into a single page, so it runs from a plain file with no server. The payload is
gzipped and base64'd; the page unpacks it with DecompressionStream and boots the
engine from memory.

Usage: python3 tools/build_single_file.py
"""
import base64
import gzip
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPO = os.path.abspath(os.path.join(ROOT, ".."))
ENGINE = os.path.join(ROOT, "web", "engine")
OUT = os.path.join(ROOT, "build", "MossAndEmber.html")
BUNDLE = os.path.join(ROOT, "build", "boot.bundle.js")
ESBUILD = os.environ.get("ESBUILD", "/tmp/browsertest/node_modules/.bin/esbuild")

# what ships inside the page: same set the web server stages, minus the worklets
# and the wasm (those get their own slots in the payload)
GAME_EXTS = {".gd", ".uid", ".tscn", ".tres", ".godot", ".json", ".svg", ".png"}
SKIP_DIRS = {"build", ".git", "web", "tools", "concepts", "docs"}


def gz_b64(raw: bytes) -> str:
    """Compress first, then base64: base64 expansion lands on the small data."""
    return base64.b64encode(gzip.compress(raw, 9)).decode()


def collect_game_files():
    files = {}
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            if os.path.splitext(fn)[1].lower() not in GAME_EXTS:
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
            with open(full, "rb") as f:
                files[rel] = f.read()
    # the title-screen icon is referenced by project.godot
    icon = os.path.join(ROOT, "icon.svg")
    if os.path.exists(icon):
        with open(icon, "rb") as f:
            files["icon.svg"] = f.read()
    return files


def bundle_boot():
    if not os.path.exists(ESBUILD):
        sys.exit(f"esbuild not found at {ESBUILD} (set ESBUILD=...)")
    cmd = [ESBUILD, os.path.join(ROOT, "web", "boot.js"), "--bundle", "--format=iife",
           "--platform=browser", "--target=es2020", "--minify",
           "--define:import.meta.url=\"'./'\"",
           f"--outfile={BUNDLE}", "--log-level=warning"]
    subprocess.run(cmd, check=True, cwd=ROOT)
    with open(BUNDLE, encoding="utf-8") as f:
        return f.read()


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    game = collect_game_files()
    # every blob is gzip-compressed and then base64'd (not the other way round)
    payload = {
        "gz": True,
        "wasm": gz_b64(open(os.path.join(ENGINE, "godot.wasm"), "rb").read()),
        "worklets": {
            "godot.audio.worklet.js": open(os.path.join(ENGINE, "audio.worklet.js"), encoding="utf-8").read(),
            "godot.audio.position.worklet.js": open(os.path.join(ENGINE, "audio.position.worklet.js"), encoding="utf-8").read(),
        },
        "files": {k: gz_b64(v) for k, v in game.items()},
    }
    # the payload goes in as plain JSON/JS object text — no outer base64, which
    # would just re-expand the already-compressed blobs by another third
    packed = json.dumps(payload, separators=(",", ":"))
    boot_js = bundle_boot()

    with open(os.path.join(ROOT, "web", "index.html"), encoding="utf-8") as f:
        html = f.read()
    # inline the boot bundle as a classic script (works from file:// too) and put
    # the payload before it
    old_tag = '<script type="module" src="./boot.js"></script>'
    if old_tag not in html:
        sys.exit("index.html no longer has the boot.js script tag")
    file_shim = (
        "<script>\n"
        "// Godot's web glue looks up a service worker registration during engine\n"
        "// startup, which throws on file:// — stub it so the offline build boots.\n"
        "if (location.protocol === 'file:' && navigator.serviceWorker) {\n"
        "  try { Object.defineProperty(navigator, 'serviceWorker', {\n"
        "    configurable: true,\n"
        "    value: { controller: null, ready: Promise.resolve(null),\n"
        "      getRegistration: function () { return Promise.resolve(undefined); },\n"
        "      getRegistrations: function () { return Promise.resolve([]); },\n"
        "      register: function () { return Promise.resolve(undefined); },\n"
        "      addEventListener: function () {}, removeEventListener: function () {} } });\n"
        "  } catch (e) {}\n"
        "}\n"
        "</script>\n"
    )
    html = html.replace(old_tag,
                        file_shim +
                        '<script>window.__MOSS_PAYLOAD=' + packed + ';</script>\n'
                        '<script>' + boot_js + '</script>')
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(html)
    os.remove(BUNDLE)
    mb = os.path.getsize(OUT) / 1024 / 1024
    print(f"built {OUT} ({mb:.1f} MB, {len(game)} game files inlined)")

    # Keep a copy in the repo's docs/ folder and index it, so the whole game can
    # be downloaded from GitHub (docs/index.html is a link page).
    docs = os.path.join(REPO, "docs")
    os.makedirs(docs, exist_ok=True)
    shutil.copy(OUT, os.path.join(docs, "MossAndEmber.html"))
    print(f"copied to {os.path.join(docs, 'MossAndEmber.html')}")


if __name__ == "__main__":
    main()
