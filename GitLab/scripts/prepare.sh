#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

set -eo pipefail

token=$(curl -sd '{"email":'\"$CUSTOM_ENV_ORKA_USER\"', "password":'\"$CUSTOM_ENV_ORKA_PASSWORD\"'}' -H "Content-Type: application/json" -X POST $CUSTOM_ENV_ORKA_ENDPOINT/token | jq -r '.token')

vm=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" $CUSTOM_ENV_ORKA_ENDPOINT/resources/vm/status/$CUSTOM_ENV_ORKA_VM_NAME)

required_cpu=$(echo $vm | jq '.virtual_machine_resources[0].cpu')
if [ "$required_cpu" == "null" ]; then
    required_cpu=$(echo $vm | jq '.virtual_machine_resources[0].status[0].cpu')
fi

node=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" $CUSTOM_ENV_ORKA_ENDPOINT/resources/node/list | jq -r '[.nodes[]|select(.available_cpu >= '\"$required_cpu\"')][0].name')
vm_info=$(curl -sd '{"orka_vm_name":'\"$CUSTOM_ENV_ORKA_VM_NAME\"', "orka_node_name":'\"$node\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST $CUSTOM_ENV_ORKA_ENDPOINT/resources/vm/deploy)

vm_id=$(echo $vm_info | jq -r '.vm_id')
echo "$vm_id;$node" > $BUILD_ID

vm_ip=$(echo $vm_info | jq -r '.ip')
vm_ssh_port=$(echo $vm_info | jq -r '.ssh_port')
echo "$vm_ip;$vm_ssh_port" > $CONNECTION_INFO_ID