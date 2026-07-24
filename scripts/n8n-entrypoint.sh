#!/bin/sh
# Ensure bind-mounted n8n data is writable by the node user, then drop privileges.
set -eu

N8N_HOME="${N8N_USER_FOLDER:-/home/node/.n8n}"

mkdir -p "${N8N_HOME}"
chown -R node:node "${N8N_HOME}"
chmod 700 "${N8N_HOME}" || true
if [ -f "${N8N_HOME}/config" ]; then
  chmod 600 "${N8N_HOME}/config" || true
fi

export N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS="${N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS:-true}"

# BusyBox setpriv cannot change uid; drop via su.
if [ "$#" -gt 0 ]; then
  exec su node -s /bin/sh -c 'exec tini -- /docker-entrypoint.sh "$@"' -- "$@"
fi

exec su node -s /bin/sh -c 'exec tini -- /docker-entrypoint.sh'
