#!/usr/bin/env sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command '$1' was not found." >&2
    exit 1
  }
}
require_environment() {
  [ -f .env ] || {
    echo "Error: .env is missing. Copy .env.example to .env and edit it." >&2
    exit 1
  }
  set -- POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD
  for variable do
    value=$(sed -n "s/^${variable}=//p" .env | tail -n 1)
    [ -n "$value" ] || {
      echo "Error: $variable is missing or empty in .env." >&2
      exit 1
    }
  done
}

compose() {
  docker compose "$@"
}

wait_for_health() {
  timeout=${HEALTH_TIMEOUT:-120}
  elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    states=$(compose ps --format json 2>/dev/null || true)
    unhealthy=$(printf '%s\n' "$states" | grep -E '"Health":"(unhealthy|starting)"' || true)
    running=$(printf '%s\n' "$states" | grep -c '"State":"running"' || true)
    if [ -z "$unhealthy" ] && [ "$running" -ge 3 ]; then
      echo "All services are running and healthy."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "Error: services did not become healthy within ${timeout}s." >&2
  compose ps
  return 1
}
