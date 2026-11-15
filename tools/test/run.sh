#!/usr/bin/env bash
# Ejecuta tools/test/test.brs con el interprete brs y falla si alguna prueba falla.
set -uo pipefail
cd "$(dirname "$0")/../.."

out=$(npx brs tools/test/test.brs app/components/HtmlParser.brs app/components/AdFilter.brs --root . 2>&1)
echo "$out"
summary=$(echo "$out" | grep -E '^PRUEBAS:' || true)
if [[ -z "$summary" ]]; then
    echo "ERROR: las pruebas no terminaron" >&2
    exit 1
fi
if ! echo "$summary" | grep -qE ' 0 fallidas'; then
    exit 1
fi
