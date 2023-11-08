#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${currentDir}/base.sh"

set -euo pipefail

orka_config_name=${ORKA_CONFIG_NAME:-}
orka_vm_name_prefix=${ORKA_VM_NAME_PREFIX:-gh-runner}
orka_vm_user=${ORKA_VM_USER:-admin}
runner_count=${RUNNER_COUNT:-1}
ssh_key_location=${SSH_KEY_LOCATION:-$HOME/.ssh/id_rsa}
github_token=${GITHUB_TOKEN:-}
repository=${REPOSITORY:-}
version=${RUNNER_VERSION:-"2.309.0"}
type=${RUNNER_RUN_TYPE:-"service"}
group=${RUNNER_GROUP:-"default"}
labels=${RUNNER_LABELS:-"macOS"}
cpu=${CPU_TYPE:-"x64"}
settings_file=${SETTINGS_FILE:-"${currentDir}/settings.json"}

while [[ "$#" -gt 0 ]]
do
case $1 in
    -p|--orka_vm_name_prefix)
      orka_vm_name_prefix=$2
      ;;
    -cfg|--orka_config_name)
      orka_config_name=$2
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
    -t|--github_token|--token)
      github_token=$2
      ;;
    -r|--repository|--url)
      repository=$2
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
    -c|--cpu)
      cpu=$2
      ;;
    -sf|--settings_file)
      settings_file=$2
      ;;
    *)
      echo "Error: unknown flag: $1" 1>&2
      exit 1
      ;;
esac
shift 2
done

if [ -z "$github_token" ]; then
  echo "Error: GITHUB_TOKEN not set" 1>&2
  exit 1
fi

if [ -z "$repository" ]; then
  echo "Error: REPOSITORY not set" 1>&2
  exit 1
fi

if [ -z "$orka_config_name" ]; then
  echo "Error: ORKA_CONFIG_NAME not set" 1>&2
  exit 1
fi

for r in $(seq 1 "$runner_count"); do
    echo "Booting VM #$r..."

    set +e
    vm_info=$(orka3 vm deploy --config "$orka_config_name" --generate-name "$orka_vm_name_prefix" -o json 2>&1)
    if [ $? -ne 0 ]; then
        echo "VM deploy failed with $vm_info" 1>&2
        exit 1
    fi
    set -e

    vm_name=$(echo "$vm_info" | jq -r '.[0]|.name')

    echo "VM deployed with name $vm_name"

    vm_ip=$(echo "$vm_info" | jq -r '.[0]|.ip')
    vm_ip=$(map_ip "$vm_ip" "$settings_file")
    vm_ssh_port=$(echo "$vm_info" | jq -r '.[0]|.ssh')

    if ! valid_ip "$vm_ip"; then
        echo "Invalid IP: $vm_ip"
        exit 1
    fi

    if [ -z "$vm_ssh_port" ]; then
        echo "Invalid port: $vm_ssh_port"
        exit 1
    fi

    echo "Connecting to $vm_ip:$vm_ssh_port"

    echo "Waiting for sshd to be available"
    for i in $(seq 1 30); do
        if ssh -i "$ssh_key_location" \
          -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          "$orka_vm_user@$vm_ip" -p "$vm_ssh_port" "echo ok" >/dev/null 2>/dev/null; then
            break
        fi

        if [ "$i" == "30" ]; then
            echo 'Waited 30 seconds for sshd to start, exiting...'
            exit 1
        fi

        sleep 1
    done

    env_vars=(
        GITHUB_TOKEN="$github_token"
        REPOSITORY="$repository"
        RUNNER_NAME="$vm_name"
        RUNNER_VERSION="$version"
        RUNNER_RUN_TYPE="$type"
        RUNNER_GROUP="$group"
        RUNNER_LABELS="$labels"
        CPU_TYPE="$cpu"
    )

    echo 'Connecting to VM and setting up agent'
    ssh -i "$ssh_key_location" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "${orka_vm_user}@${vm_ip}" -p "$vm_ssh_port" env "${env_vars[@]}" "bash -s" < "$currentDir/setup-runner.sh"
done
