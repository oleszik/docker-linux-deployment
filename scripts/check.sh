#!/usr/bin/env sh
set -eu
# shellcheck source=common.sh
. "$(dirname -- "$0")/common.sh"

require_command docker
echo "Docker version"
docker --version
docker compose version
printf '\nProject services\n'
compose ps
printf '\nProject networks\n'
compose config --networks
printf '\nProject volumes\n'
compose config --volumes
printf '\nHost filesystem usage\n'
df -h "$project_root"
printf '\nDocker disk usage\n'
docker system df
