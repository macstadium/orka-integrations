#!/bin/bash

set -o errexit -o nounset -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# shellcheck source=GitLab/scripts/base.sh
source "${currentDir}/base.sh"

trap system_failure ERR

echo "Authenticating with Orka..."

auth_response=$(curl -m 60 -sd '{"email": "'"$ORKA_USER"'", "password": "'"$ORKA_PASSWORD"'"}' -H "Content-Type: application/json" -X POST "$ORKA_ENDPOINT/token")
error_msg=$(echo "$auth_response" | jq -r '.errors[]?.message')
if [ "$error_msg" ]; then
    echo "Auth to $ORKA_ENDPOINT failed with: $error_msg"
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi
token=$(echo "$auth_response" | jq -r '.token')
trap 'revoke_token $token $ORKA_ENDPOINT' EXIT

echo "Authenticated."

echo "Deploying a VM..."

vm_info=$(curl -m 60 -sd '{"orka_vm_name": "'"$ORKA_VM_NAME"'"}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST "$ORKA_ENDPOINT/resources/vm/deploy")

error_msg=$(echo "$vm_info" | jq -r '.errors[]?.message')
if [ "$error_msg" ]; then
    echo "VM deploy failed with: $error_msg"
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi

echo "VM deployed."

vm_id=$(echo "$vm_info" | jq -r '.vm_id')
echo "$vm_id" > "$BUILD_ID"

vm_ip=$(echo "$vm_info" | jq -r '.ip')
vm_ip=$(map_ip "$vm_ip")
vm_ssh_port=$(echo "$vm_info" | jq -r '.ssh_port')

if ! valid_ip "$vm_ip"; then
    echo "Invalid ip: $vm_ip"
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi

if [ -z "$vm_ssh_port" ]; then
    echo "Invalid port: $vm_ssh_port"
    exit "$SYSTEM_FAILURE_EXIT_CODE"
fi

echo "$vm_ip;$vm_ssh_port" > "$CONNECTION_INFO_ID"

echo "Connecting to $vm_ip:$vm_ssh_port ($ORKA_VM_NAME - vm_id=$vm_id)"

echo "Waiting for sshd to be available..."
for i in $(seq 1 30); do
    if ssh -i /root/.ssh/id_rsa -o ConnectTimeout=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" "echo ok" >/dev/null 2>/dev/null; then
        break
    fi

    if [ "$i" == "30" ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...'
        exit "$SYSTEM_FAILURE_EXIT_CODE"
    fi

    sleep 1s
done
