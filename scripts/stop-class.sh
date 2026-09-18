#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS="$ROOT/logs"

for name in api-tunnel web-tunnel frontend backend; do
  pid_file="$LOGS/$name.pid"
  if [[ -f "$pid_file" ]]; then
    pid="$(<"$pid_file")"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi
done

if [[ "${1:-}" != "--keep-database" ]]; then
  docker compose --project-directory "$ROOT/backend" -p conduit down
fi

printf 'Class stack stopped.\n'
