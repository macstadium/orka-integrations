#!/bin/bash

set -eu -o pipefail

SERVER_URL=${SERVER_URL:-https://gitlab.com}
TOKEN=${TOKEN:-}

if [ -z "$SERVER_URL" ]; then
  echo "Error: SERVER_URL not set" 1>&2
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo "Error: TOKEN not set" 1>&2
  exit 1
fi

# gitlab-runner data directory
DATA_DIR="/etc/gitlab-runner"
CONFIG_FILE=${CONFIG_FILE:-$DATA_DIR/config.toml}
# custom certificate authority path
CA_CERTIFICATES_PATH=${CA_CERTIFICATES_PATH:-$DATA_DIR/certs/ca.crt}
LOCAL_CA_PATH="/usr/local/share/ca-certificates/ca.crt"

update_ca() {
  echo "Updating CA certificates..."
  cp "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}"
  update-ca-certificates --fresh >/dev/null
}

if [ -f "${CA_CERTIFICATES_PATH}" ]; then
  # update the ca if the custom ca is different than the current
  cmp -s "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}" || update_ca
fi

gitlab-runner register \
    --non-interactive \
    --executor "custom" \
    --url "$SERVER_URL" \
    --token "$TOKEN" \
    --description="orka-runner" \
    --builds-dir "/tmp/builds" \
    --cache-dir "/tmp/cache" \
    --custom-run-exec "/var/custom-executor/run.sh" \
    --custom-prepare-exec "/var/custom-executor/prepare.sh" \
    --custom-cleanup-exec "/var/custom-executor/cleanup.sh"

exec gitlab-runner "$@"
