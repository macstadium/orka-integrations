#!/bin/bash

set -eu -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${currentDir}/base.sh"

trap system_failure ERR

connection_info=$(<"$CONNECTION_INFO_ID")
IFS=';' read -ra info <<< "$connection_info"
vm_ip=${info[0]}
vm_ssh_port=${info[1]}

ssh -i "$ORKA_SSH_KEY_FILE" \
  -o ServerAliveInterval=60 -o ServerAliveCountMax=60 "$ORKA_VM_USER@$vm_ip" -p "$vm_ssh_port" /bin/bash -l < "${1}"
