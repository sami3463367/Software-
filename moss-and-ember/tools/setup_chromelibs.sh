#!/usr/bin/env bash
# Prepare a headless Chromium for the browser smoke test (tools/boottest.cjs).
#
# The sandbox has no root and no Chrome of its own, so we use the npm packages
# puppeteer-core + @sparticuz/chromium (a Chromium build that needs only three
# extra libraries, which that package also ships as brotli archives).
#
# Usage:  bash tools/setup_chromelibs.sh [npmdir]
#   npmdir defaults to /tmp/browsertest (see tools/boottest.cjs header)
set -euo pipefail

NPMDIR="${1:-/tmp/browsertest}"
PKG="$NPMDIR/node_modules/@sparticuz/chromium"
DEST=/tmp/chromelibs

if [ ! -d "$PKG" ]; then
  echo "installing puppeteer-core + @sparticuz/chromium in $NPMDIR ..."
  mkdir -p "$NPMDIR"
  (cd "$NPMDIR" && npm init -y >/dev/null 2>&1 && npm i --silent puppeteer-core @sparticuz/chromium)
fi

rm -rf "$DEST"
mkdir -p "$DEST"
node -e '
const zlib = require("zlib"), fs = require("fs"), path = require("path");
const pkg = process.argv[1], dest = process.argv[2];
for (const [src, out] of [["bin/al2023.tar.br", "al2023.tar"], ["bin/swiftshader.tar.br", "swiftshader.tar"]]) {
  const buf = zlib.brotliDecompressSync(fs.readFileSync(path.join(pkg, src)));
  fs.writeFileSync(path.join(dest, out), buf);
  console.log("decompressed", src, "->", (buf.length / 1024 / 1024).toFixed(2), "MB");
}
' "$PKG" "$DEST"

tar xf "$DEST/al2023.tar" -C "$DEST"
tar xf "$DEST/swiftshader.tar" -C "$DEST"
rm -f "$DEST/al2023.tar" "$DEST/swiftshader.tar"
echo "chromium support libraries ready in $DEST"
echo "run:  EXTRA_LIBS=$DEST/lib:$DEST NODE_PATH=$NPMDIR/node_modules node tools/boottest.cjs"
