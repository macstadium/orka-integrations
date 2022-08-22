#!/bin/bash
set -euo pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

buildkite-hook environment "$BUILDKITE_HOOKS_PATH/environment"

trap 'buildkite-hook "pre-exit" "$BUILDKITE_HOOKS_PATH/pre-exit"' EXIT

echo "~~~ Deploying ephemeral agent"

token=$(curl -m 60 -sd '{"email":'\"$ORKA_USER\"', "password":'\"$ORKA_PASSWORD\"'}' -H "Content-Type: application/json" -X POST $ORKA_ENDPOINT/token | jq -r '.token')

trap 'revoke_token $token $ORKA_ENDPOINT' ERR
vm_info=$(curl -m ${DEPLOY_TIMEOUT:-900} -sd '{"orka_vm_name":'\"$ORKA_VM_NAME\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST $ORKA_ENDPOINT/resources/vm/deploy)
errors=$(echo $vm_info | jq -r '.errors[]?.message')

while [ "$errors" ]
do
    echo "VM deploy failed with: $errors"
    echo "Waiting for 10 seconds"
    sleep 10
    echo "Retrying VM deployment..."
    vm_info=$(curl -m ${DEPLOY_TIMEOUT:-60} -sd '{"orka_vm_name":'\"$ORKA_VM_NAME\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST $ORKA_ENDPOINT/resources/vm/deploy)
    errors=$(echo $vm_info | jq -r '.errors[]?.message')
done
revoke_token $token $ORKA_ENDPOINT
trap '' ERR

vm_id=$(echo $vm_info | jq -r '.vm_id')
echo "$vm_id" > $CONNECTION_INFO_FILE

vm_ip=$(echo $vm_info | jq -r '.ip')
vm_ip=$(map_ip $vm_ip)
vm_ssh_port=$(echo $vm_info | jq -r '.ssh_port')

if ! valid_ip $vm_ip; then
    echo "Invalid ip: $vm_ip"
    exit -1
fi

if [ -z "$vm_ssh_port" ]; then
    echo "Invalid port: $vm_ssh_port"
    exit -1
fi

echo "Connecting to $vm_ip:$vm_ssh_port"

echo "Waiting for sshd to be available"
for i in $(seq 1 30); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ORKA_VM_USER@$vm_ip -p $vm_ssh_port "echo ok"  >/dev/null 2>/dev/null; then
        break
    fi

    if [ "$i" == "30" ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...'
        exit -1
    fi

    sleep 1s
done

env_vars=$(<$BUILDKITE_ENV_FILE)

env_vars+=(
    BUILDKITE_AGENT_ACCESS_TOKEN=${BUILDKITE_AGENT_ACCESS_TOKEN_SUBAGENT:-$BUILDKITE_AGENT_ACCESS_TOKEN}
    BUILDKITE_BUILD_PATH=${BUILDKITE_BUILD_PATH_SUBAGENT:-$BUILDKITE_BUILD_PATH}
    BUILDKITE_HOOKS_PATH=${BUILDKITE_HOOKS_PATH_SUBAGENT:-$BUILDKITE_HOOKS_PATH}
    BUILDKITE_PLUGINS_PATH=${BUILDKITE_PLUGINS_PATH_SUBAGENT:-$BUILDKITE_PLUGINS_PATH}
    BUILDKITE_PLUGINS_ENABLED=${BUILDKITE_PLUGINS_ENABLED_SUBAGENT:-$BUILDKITE_PLUGINS_ENABLED}
    BUILDKITE_PLUGIN_VALIDATION=${BUILDKITE_PLUGIN_VALIDATION_SUBAGENT:-$BUILDKITE_PLUGIN_VALIDATION}
    BUILDKITE_LOCAL_HOOKS_ENABLED=${BUILDKITE_LOCAL_HOOKS_ENABLED_SUBAGENT:-$BUILDKITE_LOCAL_HOOKS_ENABLED}
    BUILDKITE_SSH_KEYSCAN=${BUILDKITE_SSH_KEYSCAN_SUBAGENT:-$BUILDKITE_SSH_KEYSCAN}
    BUILDKITE_AGENT_DEBUG=${BUILDKITE_AGENT_DEBUG_SUBAGENT:-$BUILDKITE_AGENT_DEBUG}
)

echo "~~~ Delegating job to the ephemeral agent"

ssh -A -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ORKA_VM_USER@$vm_ip -p $vm_ssh_port env ${env_vars[@]} /bin/bash -s < ${currentDir}/run.sh
