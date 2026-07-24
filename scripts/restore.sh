#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <backup-archive.tar.gz>"
  echo
  echo "Available backups:"
  ls -1t "${BACKUP_DIR}"/ai-stack-*.tar.gz 2>/dev/null || echo "  (none found in ${BACKUP_DIR})"
  exit 1
fi

ARCHIVE="$1"
if [[ ! -f "${ARCHIVE}" ]]; then
  if [[ -f "${BACKUP_DIR}/${ARCHIVE}" ]]; then
    ARCHIVE="${BACKUP_DIR}/${ARCHIVE}"
  else
    echo "Error: archive not found: $1"
    exit 1
  fi
fi

echo "==> Stopping stack"
docker compose -f "${ROOT_DIR}/docker-compose.yml" down

echo "==> Restoring from ${ARCHIVE}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

if [[ -d "${TMP_DIR}/data" ]]; then
  rm -rf "${ROOT_DIR}/data"
  mkdir -p "${ROOT_DIR}/data"
  cp -a "${TMP_DIR}/data/." "${ROOT_DIR}/data/"
fi

[[ -f "${TMP_DIR}/searxng/settings.yml" ]] && cp "${TMP_DIR}/searxng/settings.yml" "${ROOT_DIR}/searxng/settings.yml"
[[ -f "${TMP_DIR}/caddy/Caddyfile" ]] && cp "${TMP_DIR}/caddy/Caddyfile" "${ROOT_DIR}/caddy/Caddyfile"

echo "==> Starting stack"
docker compose -f "${ROOT_DIR}/docker-compose.yml" up -d

SQL_DUMP="$(find "${TMP_DIR}" -maxdepth 1 -name 'postgres-*.sql' | head -n1 || true)"
if [[ -n "${SQL_DUMP}" ]]; then
  # shellcheck disable=SC1091
  set -a
  [[ -f "${ROOT_DIR}/.env" ]] && source "${ROOT_DIR}/.env"
  set +a

  echo "==> Waiting for Postgres"
  for _ in $(seq 1 30); do
    if docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T postgres \
      pg_isready -U "${POSTGRES_USER:-argus}" -d "${POSTGRES_DB:-argus}" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  echo "==> Restoring PostgreSQL dump"
  docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T postgres \
    psql -U "${POSTGRES_USER:-argus}" -d "${POSTGRES_DB:-argus}" < "${SQL_DUMP}"
fi

echo "==> Restore complete"
