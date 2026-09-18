#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"
LOGS="$ROOT/logs"
LOCAL_ONLY=false

# shellcheck disable=SC1091
source "$ROOT/scripts/lib/http.sh"

if [[ "${1:-}" == "--local-only" ]]; then
  LOCAL_ONLY=true
elif [[ -n "${1:-}" ]]; then
  printf 'Usage: %s [--local-only]\n' "$0" >&2
  exit 2
fi

mkdir -p "$LOGS"
"$ROOT/scripts/stop-class.sh" --keep-database >/dev/null 2>&1 || true

if [[ ! -f "$BACKEND/.env" ]]; then
  umask 077
  {
    echo "APP_ENV=prod"
    echo "SECRET_KEY=$(openssl rand -hex 32)"
    echo "JWT_SECRET_KEY=$(openssl rand -hex 32)"
    echo "POSTGRES_USER=conduit"
    echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)"
    echo "POSTGRES_DB=conduit"
    echo "POSTGRES_HOST=127.0.0.1"
    echo "POSTGRES_PORT=5455"
  } > "$BACKEND/.env"
fi

if [[ ! -x "$BACKEND/.venv/bin/python" ]]; then
  python3 -m venv "$BACKEND/.venv"
fi
"$BACKEND/.venv/bin/python" -m pip install -q -r "$BACKEND/requirements.txt"
"$BACKEND/.venv/bin/python" -m pip install -q -r "$ROOT/requirements-tests.txt"

if [[ ! -d "$FRONTEND/node_modules" ]]; then
  npm --prefix "$FRONTEND" install --no-package-lock
fi

docker compose --project-directory "$BACKEND" -p conduit up -d --wait postgres

set -a
# shellcheck disable=SC1091
source "$BACKEND/.env"
set +a

(
  cd "$BACKEND"
  .venv/bin/alembic upgrade head
)

nohup "$BACKEND/.venv/bin/uvicorn" conduit.app:app \
  --app-dir "$BACKEND" --host 127.0.0.1 --port 8000 \
  >"$LOGS/backend.log" 2>&1 &
echo $! > "$LOGS/backend.pid"

wait_for_http "http://127.0.0.1:8000/api/tags" "Backend"

export REACT_PUBLIC_API_ENDPOINT="http://127.0.0.1:8000/api"
export SESSION_SECRET="$(openssl rand -hex 32)"
npm --prefix "$FRONTEND" run build
nohup env PORT=3000 REACT_PUBLIC_API_ENDPOINT="$REACT_PUBLIC_API_ENDPOINT" \
  SESSION_SECRET="$SESSION_SECRET" npm --prefix "$FRONTEND" start \
  >"$LOGS/frontend.log" 2>&1 &
echo $! > "$LOGS/frontend.pid"

wait_for_http "http://127.0.0.1:3000" "Frontend"

if [[ "$LOCAL_ONLY" == true ]]; then
  printf 'API_URL=http://127.0.0.1:8000\nWEB_URL=http://127.0.0.1:3000\n' > "$ROOT/class-urls.txt"
  printf '\nLocal class stack is ready:\n'
  printf 'API_URL=http://127.0.0.1:8000\nWEB_URL=http://127.0.0.1:3000\n'
  printf '\nStop it with ./scripts/stop-class.sh\n'
  exit 0
fi

nohup cloudflared tunnel --no-autoupdate --url http://127.0.0.1:8000 \
  >"$LOGS/api-tunnel.log" 2>&1 &
echo $! > "$LOGS/api-tunnel.pid"
nohup cloudflared tunnel --no-autoupdate --url http://127.0.0.1:3000 \
  >"$LOGS/web-tunnel.log" 2>&1 &
echo $! > "$LOGS/web-tunnel.pid"

read_tunnel_url() {
  local log_file="$1"
  local url=""
  for _ in {1..45}; do
    url="$(grep -Eo 'https://[-a-z0-9]+\.trycloudflare\.com' "$log_file" | head -n 1 || true)"
    [[ -n "$url" ]] && printf '%s\n' "$url" && return 0
    sleep 1
  done
  return 1
}

API_URL="$(read_tunnel_url "$LOGS/api-tunnel.log")"
WEB_URL="$(read_tunnel_url "$LOGS/web-tunnel.log")"
printf 'API_URL=%s\nWEB_URL=%s\n' "$API_URL" "$WEB_URL" > "$ROOT/class-urls.txt"

printf '\nClass stack is ready. Write these on the board:\n'
printf 'API_URL=%s\nWEB_URL=%s\n' "$API_URL" "$WEB_URL"
printf '\nStop it with ./scripts/stop-class.sh\n'
