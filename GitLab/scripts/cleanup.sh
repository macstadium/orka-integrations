#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

set -eo pipefail

token=$(curl -sd '{"email":'\"$CUSTOM_ENV_ORKA_USER\"', "password":'\"$CUSTOM_ENV_ORKA_PASSWORD\"'}' -H "Content-Type: application/json" -X POST $CUSTOM_ENV_ORKA_ENDPOINT/token | jq -r '.token')

cleanup_info=$(<$BUILD_ID)
IFS=';' read -ra info <<< "$cleanup_info"
vm_id=${info[0]}
node=${info[1]}

curl -sd '{"orka_vm_name":'\"$vm_id\"', "orka_node_name":'\"$node\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X DELETE $CUSTOM_ENV_ORKA_ENDPOINT/resources/vm/delete
