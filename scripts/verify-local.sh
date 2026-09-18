#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
trap '"$ROOT/scripts/stop-class.sh" >/dev/null 2>&1 || true' EXIT

"$ROOT/scripts/run-class.sh" --local-only
"$ROOT/backend/.venv/bin/python" -m pytest \
  "$ROOT/tests/unit" "$ROOT/tests/integration" "$ROOT/tests/e2e" -q
