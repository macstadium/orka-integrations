#!/bin/bash

set -o errexit -o nounset -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# shellcheck source=GitLab/scripts/base.sh
source "${currentDir}/base.sh"

trap system_failure ERR

echo "Cleaning up..."

if [[ -f "$BUILD_ID" ]]; then
    echo "Authenticating with Orka..."
    
    token=$(curl -m 60 -sd '{"email": "'"$ORKA_USER"'", "password": "'"$ORKA_PASSWORD"'"}' -H "Content-Type: application/json" -X POST "$ORKA_ENDPOINT/token" | jq -r '.token')

    trap 'revoke_token $token $ORKA_ENDPOINT' EXIT

    vm_id=$(<"$BUILD_ID")

    echo "Deleting VM..."

    curl -m 60 -sd '{"orka_vm_name": "'"$vm_id"'"}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X DELETE "$ORKA_ENDPOINT/resources/vm/delete"

    echo "VM deleted."
fi
