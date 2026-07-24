#!/usr/bin/env bash
# Generate a self-signed TLS cert for local HTTPS (optional).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="${ROOT_DIR}/data/nginx/certs"
DAYS="${CERT_DAYS:-825}"

# shellcheck disable=SC1091
set -a
[[ -f "${ROOT_DIR}/.env" ]] && source "${ROOT_DIR}/.env"
set +a

DOMAINS=(
  "${DOMAIN_WEBUI:-webui.localhost}"
  "${DOMAIN_N8N:-n8n.localhost}"
  "${DOMAIN_SEARXNG:-search.localhost}"
  "${DOMAIN_QDRANT:-qdrant.localhost}"
)

mkdir -p "${CERT_DIR}"

SAN_ENTRIES=()
for d in "${DOMAINS[@]}"; do
  SAN_ENTRIES+=("DNS:${d}")
done
# shellcheck disable=SC2001
SAN="$(IFS=,; echo "${SAN_ENTRIES[*]}")"

echo "==> Writing self-signed cert for: ${DOMAINS[*]}"
openssl req -x509 -nodes -newkey rsa:2048 -days "${DAYS}" \
  -keyout "${CERT_DIR}/privkey.pem" \
  -out "${CERT_DIR}/fullchain.pem" \
  -subj "/CN=${DOMAINS[0]}/O=Argus AI Stack" \
  -addext "subjectAltName=${SAN}"

chmod 644 "${CERT_DIR}/fullchain.pem"
chmod 600 "${CERT_DIR}/privkey.pem"

echo "==> Certs written to ${CERT_DIR}"
echo "    To enable HTTPS: copy nginx/templates/webui-ssl.conf.template.example"
echo "    to nginx/templates/webui-ssl.conf.template (and similar for other hosts),"
echo "    then: docker compose up -d nginx"
