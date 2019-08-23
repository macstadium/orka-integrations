#!/bin/bash
set -euo pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

buildkite-hook environment "$BUILDKITE_HOOKS_PATH/environment"

trap 'buildkite-hook "pre-exit" "$BUILDKITE_HOOKS_PATH/pre-exit"' EXIT

echo "~~~ Deploying ephemeral agent"

token=$(curl -sd '{"email":'\"$ORKA_USER\"', "password":'\"$ORKA_PASSWORD\"'}' -H "Content-Type: application/json" -X POST $ORKA_ENDPOINT/token | jq -r '.token')

vm=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" $ORKA_ENDPOINT/resources/vm/status/$ORKA_VM_NAME)

required_cpu=$(echo $vm | jq '.virtual_machine_resources[0].cpu')
if [ "$required_cpu" == "null" ]; then
    required_cpu=$(echo $vm | jq '.virtual_machine_resources[0].status[0].cpu')
fi

node=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" $ORKA_ENDPOINT/resources/node/list | jq -r '[.nodes[]|select(.available_cpu >= '\"$required_cpu\"')][0].name')
vm_info=$(curl -sd '{"orka_vm_name":'\"$ORKA_VM_NAME\"', "orka_node_name":'\"$node\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST $ORKA_ENDPOINT/resources/vm/deploy)

vm_id=$(echo $vm_info | jq -r '.vm_id')
echo "$vm_id;$node" > $CONNECTION_INFO_FILE

vm_ip=$(echo $vm_info | jq -r '.ip')
vm_ssh_port=$(echo $vm_info | jq -r '.ssh_port')

echo "Waiting for sshd to be available"
for i in $(seq 1 30); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ORKA_VM_USER@$vm_ip -p $vm_ssh_port "echo ok"  >/dev/null 2>/dev/null; then
        break
    fi

    if [ "$i" == "30" ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...'
        exit "$SYSTEM_FAILURE_EXIT_CODE"
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

ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ORKA_VM_USER@$vm_ip -p $vm_ssh_port env ${env_vars[@]} /bin/bash -s < ${currentDir}/run.sh
