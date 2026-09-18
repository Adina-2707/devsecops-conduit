#!/usr/bin/env bash

wait_for_http() {
  local url="$1"
  local service_name="${2:-Service}"
  local max_attempts="${3:-30}"
  local retry_delay="${4:-1}"
  local attempt
  local status="000"

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    status="$(curl -sS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)"
    if [[ "$status" == "200" ]]; then
      return 0
    fi

    if ((attempt < max_attempts)); then
      sleep "$retry_delay"
    fi
  done

  printf '%s did not return HTTP 200 after %s attempts (last status: %s).\n' \
    "$service_name" "$max_attempts" "$status" >&2
  return 1
}
