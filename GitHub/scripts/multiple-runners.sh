#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

set -euo pipefail

orka_user=${ORKA_USER:-}
orka_password=${ORKA_PASSWORD:-}
orka_endpoint=${ORKA_ENDPOINT:-}
orka_vm_name=${ORKA_VM_NAME:-}
orka_vm_user=${ORKA_VM_USER:-}
runner_count=${RUNNER_COUNT:-1}
ssh_key_location=${SSH_KEY_LOCATION:-$HOME/.ssh/id_rsa}
github_token=${GITHUB_TOKEN:-}
repository=${REPOSITORY:-}
version=${RUNNER_VERSION:-"2.307.1"}
type=${RUNNER_RUN_TYPE:-"service"}
group=${RUNNER_GROUP:-"default"}
labels=${RUNNER_LABELS:-"macOS"}
cpu=${CPU_TYPE:-}
settings_file=${SETTINGS_FILE:-"${currentDir}/settings.json"}
deploy_timeout=${DEPLOY_TIMEOUT:-60}

while [[ "$#" -gt 0 ]]
do
case $1 in
    -u|--orka_user)
    orka_user=$2
    ;;
    -p|--orka_password)
    orka_password=$2
    ;;
    -e|--orka_endpoint)
    orka_endpoint=$2
    ;;
    -v|--orka_vm_name)
    orka_vm_name=$2
    ;;
    -vu|--orka_vm_user)
    orka_vm_user=$2
    ;;
    -c|--runner_count)
    runner_count=$2
    ;;
    -s|--ssh_key_location)
    ssh_key_location=$2
    ;;
    -t|--github_token)
    github_token=$2
    ;;
    -r|--repository)
    repository=$2
    ;;
    -cpu|--cpu_type)
    cpu=$2
    ;;
    -rv|--runner_version)
    version=$2
    ;;
    -tp|--runner_run_type)
    type=$2
    ;;
    -g|--runner_group)
    group=$2
    ;;
    -l|--runner_labels)
    labels=$2
    ;;
    -sf|--settings_file)
    settings_file=$2
    ;;
    -dt|--deploy_timeout)
    deploy_timeout=$2
    ;;
esac
shift
done

token=$(curl -m 60 -sd '{"email":'\"$orka_user\"', "password":'\"$orka_password\"'}' -H "Content-Type: application/json" -X POST $orka_endpoint/token | jq -r '.token')

trap 'handle_exit $token $orka_endpoint' EXIT

for i in $(seq 1 $runner_count); do
    echo "Booting VM #$i"
    vm_info=$(curl -m $deploy_timeout -sd '{"orka_vm_name":'\"$orka_vm_name\"'}' -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST $orka_endpoint/resources/vm/deploy)

    errors=$(echo $vm_info | jq -r '.errors[]?.message')
    if [ "$errors" ]; then
        echo "VM deploy failed with: $errors"
        exit -1
    fi

    vm_id=$(echo $vm_info | jq -r '.vm_id')

    echo "VM deployed with id $vm_id"

    vm_ip=$(echo $vm_info | jq -r '.ip')
    vm_ip=$(map_ip $vm_ip $settings_file)
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
        if ssh -i $ssh_key_location -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $orka_vm_user@$vm_ip -p $vm_ssh_port "echo ok" >/dev/null 2>/dev/null; then
            break
        fi

        if [ "$i" == "30" ]; then
            echo 'Waited 30 seconds for sshd to start, exiting...'
            exit -1
        fi

        sleep 1
    done

    env_vars=(
        GITHUB_TOKEN=$github_token
        REPOSITORY=$repository
        RUNNER_NAME=$vm_id
        RUNNER_VERSION=$version
        RUNNER_RUN_TYPE=$type
        RUNNER_GROUP=$group
        RUNNER_LABELS=$labels
        CPU_TYPE=$cpu
    )

    echo 'Connecting to VM and setting up agent'
    ssh -i $ssh_key_location -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $orka_vm_user@$vm_ip -p $vm_ssh_port env ${env_vars[@]} "bash -s" < $currentDir/setup-runner.sh
done
