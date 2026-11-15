#!/usr/bin/env bash
# Empaqueta el canal: dist/NavegadorWebRoku.zip con manifest, source, components e images en la raiz.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p dist
rm -f dist/NavegadorWebRoku.zip
(cd app && zip -r -q -X ../dist/NavegadorWebRoku.zip manifest source components images -x '*.DS_Store')

v=$(grep -E "^(major|minor)_version=" app/manifest | cut -d= -f2 | paste -sd. -)
b=$(grep -E "^build_version=" app/manifest | cut -d= -f2)
echo "dist/NavegadorWebRoku.zip (version $v, build $b)"
