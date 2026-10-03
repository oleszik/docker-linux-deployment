#!/usr/bin/env sh
set -eu
# shellcheck source=common.sh
. "$(dirname -- "$0")/common.sh"

require_command docker
docker info >/dev/null 2>&1 || { echo "Error: Docker daemon is unavailable." >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Error: Docker Compose v2 is unavailable." >&2; exit 1; }
require_environment
compose config --quiet
compose pull --ignore-buildable
compose build --pull
compose up -d --remove-orphans
wait_for_health
compose ps
