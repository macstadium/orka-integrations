#!/bin/bash

set -eu -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${currentDir}/base.sh"

trap system_failure ERR

echo "Authenticating with Orka..."

orka3 config set --api-url "$ORKA_ENDPOINT"
orka3 user set-token "$ORKA_TOKEN"

echo "Authenticated."

echo "Deploying a VM..."

vm_info=$(orka3 vm deploy "$ORKA_VM_NAME_PREFIX" --config "$ORKA_CONFIG_NAME" --generate-name -o json)

vm_name=$(echo "$vm_info" | jq -r '.[0]|.name')

echo "VM deployed with name '$vm_name'"
echo "$vm_name" > "$BUILD_ID"

vm_ip=$(echo "$vm_info" | jq -r '.[0]|.ip')
vm_ip=$(map_ip "$vm_ip")
vm_ssh_port=$(echo "$vm_info" | jq -r '.[0]|.ssh')

if ! valid_ip "$vm_ip"; then
    echo "Invalid ip: $vm_ip" 1>&2
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi

if [ -z "$vm_ssh_port" ]; then
    echo "Invalid port: $vm_ssh_port" 1>&2
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi

echo "$vm_ip;$vm_ssh_port" > "$CONNECTION_INFO_ID"

echo "Connecting to '$vm_name' ($vm_ip:$vm_ssh_port)"

echo "Waiting for SSH access to be available..."
for i in $(seq 1 30); do
    if ssh -i "$ORKA_SSH_KEY_FILE" -o ConnectTimeout=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" "echo ok" >/dev/null 2>&1; then
        break
    fi

    if [ "$i" == "30" ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...' 1>&2
        exit "$SYSTEM_FAILURE_EXIT_CODE"
    fi

    sleep 1s
done

touch ~/.ssh/known_hosts
ssh-keygen -R "[$vm_ip]:$vm_ssh_port"
ssh-keyscan -t rsa -p "$vm_ssh_port" "$vm_ip" >> ~/.ssh/known_hosts
