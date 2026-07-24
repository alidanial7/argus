#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

echo "==> Creating pre-update backup"
"${ROOT_DIR}/scripts/backup.sh"

echo "==> Pulling latest images"
docker compose -f "${COMPOSE_FILE}" pull

echo "==> Recreating containers"
docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans

echo "==> Pruning dangling images"
docker image prune -f

echo "==> Current status"
docker compose -f "${COMPOSE_FILE}" ps

echo "==> Update complete"
