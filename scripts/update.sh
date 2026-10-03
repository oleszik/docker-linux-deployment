#!/usr/bin/env sh
set -eu
# shellcheck source=common.sh
. "$(dirname -- "$0")/common.sh"

require_command docker
require_environment
if [ "${SKIP_BACKUP:-0}" != "1" ]; then
  "$project_root/scripts/backup.sh"
fi
compose pull --ignore-buildable
compose build --pull
compose up -d --remove-orphans
wait_for_health
compose ps
