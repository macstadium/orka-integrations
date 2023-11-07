#!/bin/bash
set -euo pipefail

echo "Called bootstrap.sh with args: $@"

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${currentDir}/base.sh"

buildkite-hook environment "$BUILDKITE_HOOKS_PATH/environment"

trap 'buildkite-hook "pre-exit" "$BUILDKITE_HOOKS_PATH/pre-exit"' EXIT

ORKA_VM_NAME_PREFIX="${ORKA_VM_NAME_PREFIX:-buildkite-agent}"
ORKA_VM_USER="${ORKA_VM_USER:-admin}"

echo "~~~ Deploying ephemeral agent"

orka3 config set --api-url "$ORKA_ENDPOINT"
orka3 user set-token "$ORKA_TOKEN"

set +e
vm_info=$(orka3 vm deploy --config "$ORKA_CONFIG_NAME" --generate-name "$ORKA_VM_NAME_PREFIX" -o json 2>&1)
if [ $? -ne 0 ]; then
    echo "VM deploy failed with $vm_info" 1>&2
    exit 1
fi
set -e

vm_name=$(echo "$vm_info" | jq -r '.[0]|.name')

echo "VM deployed with name '$vm_name'"

echo "$vm_name" > "$CONNECTION_INFO_FILE"

vm_ip=$(echo "$vm_info" | jq -r '.[0]|.ip')
vm_ip=$(map_ip "$vm_ip")
vm_ssh_port=$(echo "$vm_info" | jq -r '.[0]|.ssh')

if ! valid_ip "$vm_ip"; then
    echo "Invalid ip: $vm_ip" 1>&2
    exit 1
fi

if [ -z "$vm_ssh_port" ]; then
    echo "Invalid port: $vm_ssh_port" 1>&2
    exit 1
fi

echo "Connecting to '$vm_name' ($vm_ip:$vm_ssh_port)"

echo "Waiting for sshd to be available"
for i in $(seq 1 30); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" "echo ok"  >/dev/null 2>/dev/null; then
        break
    fi

    if [ "$i" == "30" ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...' 1>&2
        exit 1
    fi

    sleep 1s
done

env_vars=$(<"$BUILDKITE_ENV_FILE")

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

ssh -A -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" env ${env_vars[@]} /bin/bash -s < "${currentDir}/run.sh"
