#!/usr/bin/env bash
# Fix bind-mount ownership so containers can write into ./data
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${ROOT_DIR}/data"

mkdir -p \
  "${DATA}/n8n" \
  "${DATA}/open-webui" \
  "${DATA}/nginx/logs" \
  "${DATA}/nginx/certs"

# n8n image runs as user `node` (uid/gid 1000)
chown -R 1000:1000 "${DATA}/n8n"

# Open WebUI typically runs as uid 1000
chown -R 1000:1000 "${DATA}/open-webui"

# Nginx master drops workers; keep logs writable by the nginx user (101 on alpine image)
chown -R 101:101 "${DATA}/nginx/logs" 2>/dev/null || true

echo "==> Permissions fixed for data volumes"
