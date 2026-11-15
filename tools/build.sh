#!/usr/bin/env bash
# Empaqueta el canal: download/NavegadorWebRoku.zip con manifest, source, components, images y filters en la raiz.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p download
rm -f download/NavegadorWebRoku.zip
(cd app && zip -r -q -X ../download/NavegadorWebRoku.zip manifest source components images filters -x '*.DS_Store')

v=$(grep -E "^(major|minor)_version=" app/manifest | cut -d= -f2 | paste -sd. -)
b=$(grep -E "^build_version=" app/manifest | cut -d= -f2)
echo "download/NavegadorWebRoku.zip (version $v, build $b)"
