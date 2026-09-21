#!/usr/bin/env python3
"""Builds the static web site for the Moss & Ember slice and serves it.

Usage: python3 web/serve.py [port]

Pipeline:
  1. Copy the vendored engine files (godot.js / godot.wasm / the two audio
     worklets, renamed to the names the engine template requests) from
     web/engine/ into build/web/.
  2. Copy the Godot project's runtime files into build/web/game/ — only the
     extensions the engine can actually load (scripts, scenes, text resources,
     project config). Audio ships as .tres resources with base64 PCM, so the
     runtime needs no import cache: everything here loads without importers.
  3. Generate files.json — the manifest boot.js stages into the engine's
     in-memory filesystem (MEMFS root == res://).
  4. Serve build/web/ on 0.0.0.0:<port> with correct MIME types, COOP/COEP,
     and no-cache for js/wasm so a rebuild is always picked up.

Engine files come from the @ringozz/godot-web-wasm32 npm package (a Godot
4.7.2 build with thread support off, which is what runs in the browser here):

    curl -sL -o ringozz.tgz \\
      https://registry.npmjs.org/@ringozz/godot-web-wasm32/-/godot-web-wasm32-4.7.2-626.tgz
    tar xzf ringozz.tgz
    cp package/gen/godot.web.template_release.wasm32.nothreads.js   web/engine/godot.js
    cp package/gen/godot.web.template_release.wasm32.nothreads.wasm web/engine/godot.wasm
    cp package/gen/audio.worklet.js          web/engine/audio.worklet.js
    cp package/gen/audio.position.worklet.js web/engine/audio.position.worklet.js
"""
import json
import os
import shutil
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ENGINE_DIR = os.path.join(ROOT, "web", "engine")
OUT = os.path.join(ROOT, "build", "web")
GAME_DIR = os.path.join(OUT, "game")

# engine file name -> also its name in build/web/
# (file in build/web/, file in web/engine/) — the engine template requests the
# worklets by their *output* names via locate_file("godot.audio.worklet.js").
ENGINE_FILES = (
    ("godot.js", "godot.js"),
    ("godot.wasm", "godot.wasm"),
    ("godot.audio.worklet.js", "audio.worklet.js"),
    ("godot.audio.position.worklet.js", "audio.position.worklet.js"),
)

# Only these extensions are worth staging into MEMFS at boot.
GAME_EXTS = {
    ".gd",      # scripts
    ".uid",     # script/scene uid sidecars (scenes reference them)
    ".tscn",    # scenes (text)
    ".tres",    # resources (text) — includes all audio
    ".godot",   # project.godot
    ".json",
    ".svg",
    ".png",
}
SKIP_DIRS = {"build", ".git", "web", "tools", "concepts"}


def build_site() -> None:
    missing = [src for _, src in ENGINE_FILES if not os.path.exists(os.path.join(ENGINE_DIR, src))]
    if missing:
        raise SystemExit(
            "engine files missing from web/engine/: %s\n"
            "see the docstring at the top of this file for the one-time fetch command"
            % ", ".join(missing)
        )

    os.makedirs(OUT, exist_ok=True)
    # 1. engine + page shell
    for dst, src in ENGINE_FILES:
        shutil.copy(os.path.join(ENGINE_DIR, src), os.path.join(OUT, dst))
    for local in ("index.html", "boot.js", "emnapi.js"):
        shutil.copy(os.path.join(ROOT, "web", local), os.path.join(OUT, local))

    # 2. project runtime files
    if os.path.exists(GAME_DIR):
        shutil.rmtree(GAME_DIR)
    os.makedirs(GAME_DIR)
    staged = 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            if os.path.splitext(fn)[1].lower() not in GAME_EXTS:
                continue
            src = os.path.join(dirpath, fn)
            rel = os.path.relpath(src, ROOT)
            dst = os.path.join(GAME_DIR, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(src, dst)
            staged += 1

    # 3. manifest — where to fetch it (http) and where to put it in MEMFS (res)
    files = []
    for dirpath, dirnames, filenames in os.walk(GAME_DIR):
        dirnames.sort()
        for fn in sorted(filenames):
            rel = os.path.relpath(os.path.join(dirpath, fn), GAME_DIR).replace(os.sep, "/")
            files.append({"http": "game/" + rel, "res": rel})
    files.sort(key=lambda e: e["res"])
    with open(os.path.join(OUT, "files.json"), "w") as f:
        json.dump({"files": files}, f, indent=1)
    total = sum(os.path.getsize(os.path.join(GAME_DIR, e["res"])) for e in files)
    print(f"built {OUT}: {len(files)} staged files, {total / 1024 / 1024:.2f} MB of game data")


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".mjs": "text/javascript",
        ".json": "application/json",
        ".pck": "application/octet-stream",
        ".w32": "application/octet-stream",
        ".ctex": "application/octet-stream",
        ".import": "text/plain",
        ".svg": "image/svg+xml",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=OUT, **kwargs)

    def end_headers(self):
        # Cross-origin isolation (needed by threaded Godot web builds; harmless
        # for the nothreads one) + always-fresh js/wasm so rebuilds show up.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        if self.path.endswith((".wasm", ".js", ".json", ".html")):
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        print("[serve]", fmt % args)


def main() -> None:
    build_site()
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"serving http://0.0.0.0:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
