#!/usr/bin/env python3
"""Builds the web/ static site for the Moss & Ember slice and serves it.

Usage: python3 serve.py [port]

Pipeline:
  1. Copy engine files (godot.js/.wasm + audio worklets) from the vendored
     @ringozz/godot-web-wasm32 package into build/web/.
  2. Copy the whole Godot project into build/web/game/ (including .godot/
     imported products + .import sidecars the runtime needs for WAV/SVG).
  3. Generate files.json — the manifest boot.js stages into MEMFS.
  4. Serve on 0.0.0.0:<port> with correct MIME types + COOP/COEP headers.
"""
import json
import os
import shutil
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ENGINE_DIR = "/home/user/tools/npm-pkgs/package/gen"
OUT = os.path.join(ROOT, "build", "web")
GAME_DIR = os.path.join(OUT, "game")

ENGINE_FILES = {
    "godot.js": "godot.web.template_release.wasm32.nothreads.js",
    "godot.wasm": "godot.web.template_release.wasm32.nothreads.wasm",
    "audio.worklet.js": "audio.worklet.js",
    "audio.position.worklet.js": "audio.position.worklet.js",
}
SKIP_DIRS = {"build", ".git", "web"}
GAME_EXTS = {".gd", ".tscn", ".tres", ".godot", ".import", ".w32", ".ctex",
             ".scn", ".pck", ".json", ".png", ".svg", ".svg2", ".w32"}


def build_site() -> None:
    os.makedirs(OUT, exist_ok=True)
    # 1. engine
    for dst, src in ENGINE_FILES.items():
        shutil.copy(os.path.join(ENGINE_DIR, src), os.path.join(OUT, dst))
    for local in ["index.html", "boot.js"]:
        shutil.copy(os.path.join(ROOT, "web", local), os.path.join(OUT, local))
    shutil.copy(os.path.join(ROOT, "web", "emnapi.js"), os.path.join(OUT, "emnapi.js"))

    # 2. project files
    if os.path.exists(GAME_DIR):
        shutil.rmtree(GAME_DIR)
    os.makedirs(GAME_DIR)
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            src = os.path.join(dirpath, fn)
            rel = os.path.relpath(src, ROOT)
            dst = os.path.join(GAME_DIR, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(src, dst)

    # 3. manifest — each entry: where to fetch from (http) and where to
    # stage it in the engine's in-memory FS (res:// = project root).
    files = []
    for dirpath, dirnames, filenames in os.walk(GAME_DIR):
        dirnames.sort()
        for fn in sorted(filenames):
            if fn in ("project.binary",):
                continue
            rel = os.path.relpath(os.path.join(dirpath, fn), GAME_DIR).replace(os.sep, "/")
            files.append({"http": "game/" + rel, "res": rel})
    files.sort(key=lambda e: e["res"])
    with open(os.path.join(OUT, "files.json"), "w") as f:
        json.dump({"files": files}, f, indent=1)
    print(f"built {OUT} with {len(files)} staged files")


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
        # Cross-origin isolation (needed by some Godot web builds; harmless
        # for the nothreads one) + long cache for the big wasm.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        if self.path.endswith(".wasm") or self.path.endswith(".js"):
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
