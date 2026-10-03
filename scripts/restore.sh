#!/usr/bin/env sh
set -eu
# shellcheck source=common.sh
. "$(dirname -- "$0")/common.sh"

require_command docker
require_environment
# shellcheck disable=SC1091
. ./.env
backup_file=${1:-}
[ -n "$backup_file" ] || { echo "Usage: $0 BACKUP_FILE [--yes]" >&2; exit 2; }
[ -f "$backup_file" ] || { echo "Error: backup file not found: $backup_file" >&2; exit 1; }

if [ "${2:-}" != "--yes" ]; then
  printf 'WARNING: this replaces objects in database %s. Type RESTORE to continue: ' "$POSTGRES_DB"
  read -r answer
  [ "$answer" = "RESTORE" ] || { echo "Restore cancelled."; exit 1; }
fi

echo "Restoring $backup_file into $POSTGRES_DB ..."
compose exec -T db pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  --clean --if-exists --no-owner --no-privileges < "$backup_file"
echo "Restore completed. Restarting application to verify connectivity."
compose restart app
wait_for_health
