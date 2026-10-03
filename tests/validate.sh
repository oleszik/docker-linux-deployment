#!/usr/bin/env sh
set -eu
cd "$(dirname -- "$0")/.."

required_files="compose.yaml .env.example app/Dockerfile app/main.py nginx/default.conf scripts/deploy.sh scripts/backup.sh scripts/restore.sh scripts/update.sh scripts/check.sh README.md"
for file in $required_files; do
  [ -f "$file" ] || { echo "Missing required file: $file" >&2; exit 1; }
done
[ ! -e .env ] || echo "Note: local .env exists and must remain ignored."
git check-ignore .env backups/test.dump >/dev/null
for script in scripts/*.sh tests/*.sh; do sh -n "$script"; done
if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh tests/*.sh; else echo "ShellCheck not installed; skipped."; fi
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose --env-file .env.example config --quiet
else
  echo "Docker Compose unavailable; compose validation skipped." >&2
  exit 1
fi
echo "Static validation passed."
