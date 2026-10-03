#!/usr/bin/env sh
set -eu
# shellcheck source=common.sh
. "$(dirname -- "$0")/common.sh"

require_command docker
require_environment
# shellcheck disable=SC1091
. ./.env
backup_dir=${BACKUP_DIR:-./backups}
retention_days=${BACKUP_RETENTION_DAYS:-7}
mkdir -p "$backup_dir"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_file="$backup_dir/${POSTGRES_DB}_${timestamp}.dump"
temporary_file="${backup_file}.tmp"
trap 'rm -f "$temporary_file"' EXIT HUP INT TERM

echo "Creating PostgreSQL backup: $backup_file"
compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$temporary_file"
[ -s "$temporary_file" ] || { echo "Error: backup is empty." >&2; exit 1; }
mv "$temporary_file" "$backup_file"
trap - EXIT HUP INT TERM
find "$backup_dir" -type f -name "${POSTGRES_DB}_*.dump" -mtime "+$retention_days" -delete
echo "Backup completed: $backup_file"
