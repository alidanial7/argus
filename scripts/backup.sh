#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK_DIR="$(mktemp -d)"
ARCHIVE="${BACKUP_DIR}/ai-stack-${STAMP}.tar.gz"

trap 'rm -rf "${WORK_DIR}"' EXIT
mkdir -p "${BACKUP_DIR}" "${WORK_DIR}/data"

echo "==> Backing up AI stack data to ${ARCHIVE}"

# shellcheck disable=SC1091
set -a
[[ -f "${ROOT_DIR}/.env" ]] && source "${ROOT_DIR}/.env"
set +a

if docker compose -f "${ROOT_DIR}/docker-compose.yml" ps --status running --services 2>/dev/null | grep -qx postgres; then
  echo "==> Dumping PostgreSQL"
  docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T postgres \
    pg_dump -U "${POSTGRES_USER:-argus}" -d "${POSTGRES_DB:-argus}" \
    > "${WORK_DIR}/postgres-${STAMP}.sql"
fi

echo "==> Collecting files"
cp -a "${ROOT_DIR}/data/." "${WORK_DIR}/data/"
mkdir -p "${WORK_DIR}/searxng" "${WORK_DIR}/nginx"
cp -a "${ROOT_DIR}/searxng/." "${WORK_DIR}/searxng/"
cp -a "${ROOT_DIR}/nginx/." "${WORK_DIR}/nginx/"
cp -a "${ROOT_DIR}/.env.example" "${WORK_DIR}/"
cp -a "${ROOT_DIR}/docker-compose.yml" "${WORK_DIR}/"

tar -czf "${ARCHIVE}" -C "${WORK_DIR}" .

echo "==> Backup complete: ${ARCHIVE}"
ls -lh "${ARCHIVE}"
