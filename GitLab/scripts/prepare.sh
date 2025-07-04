#!/bin/bash

set -eu -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${currentDir}/base.sh"

VM_DEPLOYMENT_ATTEMPTS=${CUSTOM_ENV_VM_DEPLOYMENT_ATTEMPTS:-1}

function cleanup_on_failure {
    if [ -f "$BUILD_ID" ]; then
        vm_name=$(<"$BUILD_ID")
        echo "Failure detected. Cleaning up VM '$vm_name'..." >&2
        
        orka3 vm delete "$vm_name" || echo "Failed to delete VM '$vm_name'" >&2
        
        echo "VM cleanup completed." >&2
    fi
    
    system_failure
}

function delete_vm_and_cleanup {
    if [ -f "$BUILD_ID" ]; then
        vm_name=$(<"$BUILD_ID")
        echo "Deleting VM '$vm_name'..." >&2
        orka3 vm delete "$vm_name" || echo "Failed to delete VM '$vm_name'" >&2
        rm -f "$BUILD_ID"
        rm -f "$CONNECTION_INFO_ID"
    fi
}

function attempt_deployment {
    local vm_name=$1
    
    echo "Deploying VM with name '$vm_name'..."
    
    if ! vm_info=$(orka3 vm deploy "$vm_name" --config "$ORKA_CONFIG_NAME" -o json); then
        echo "VM deployment failed" >&2
        return 1
    fi
    
    echo "VM deployed successfully."
    
    vm_ip=$(echo "$vm_info" | jq -r '.[0]|.ip')
    vm_ip=$(map_ip "$vm_ip")
    vm_ssh_port=$(echo "$vm_info" | jq -r '.[0]|.ssh')
    
    if ! valid_ip "$vm_ip"; then
        echo "Invalid ip: $vm_ip" >&2
        return 1
    fi
    
    if [ -z "$vm_ssh_port" ]; then
        echo "Invalid port: $vm_ssh_port" >&2
        return 1
    fi
    
    echo "$vm_ip;$vm_ssh_port" > "$CONNECTION_INFO_ID"
    
    echo "Connecting to '$vm_name' ($vm_ip:$vm_ssh_port)"
    
    echo "Waiting for SSH access to be available..."
    local ssh_ready=false
    for i in $(seq 1 30); do
        if ssh -i "$ORKA_SSH_KEY_FILE" -o ConnectTimeout=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" "echo ok" >/dev/null 2>&1; then
            ssh_ready=true
            break
        fi
        sleep 1s
    done
    
    if [ "$ssh_ready" = false ]; then
        echo 'Waited 30 seconds for sshd to start, exiting...' >&2
        return 1
    fi
    
    touch ~/.ssh/known_hosts
    ssh-keygen -R "[$vm_ip]:$vm_ssh_port"
    ssh-keyscan -t rsa -p "$vm_ssh_port" "$vm_ip" >> ~/.ssh/known_hosts
    
    return 0
}

trap cleanup_on_failure ERR

echo "Authenticating with Orka..."

orka3 config set --api-url "$ORKA_ENDPOINT"
orka3 user set-token "$ORKA_TOKEN"

echo "Authenticated."

for attempt in $(seq 1 "$VM_DEPLOYMENT_ATTEMPTS"); do
    echo "Deployment attempt $attempt of $VM_DEPLOYMENT_ATTEMPTS"
    
    echo "Generating VM name..."
    vm_name=$(generate_vm_name)
    echo "Generated VM name: '$vm_name'"
    echo "$vm_name" > "$BUILD_ID"
    
    if attempt_deployment "$vm_name"; then
        echo "Deployment successful on attempt $attempt"
        break
    else
        echo "Deployment attempt $attempt failed"
        
        delete_vm_and_cleanup
        
        if [ "$attempt" -eq "$VM_DEPLOYMENT_ATTEMPTS" ]; then
            echo "All deployment attempts failed. Exiting..." >&2
            exit "$SYSTEM_FAILURE_EXIT_CODE"
        else
            echo "Retrying deployment..."
            sleep 2
        fi
    fi
done
