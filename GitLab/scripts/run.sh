#!/bin/bash

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${currentDir}/base.sh

set -eo pipefail

connection_info=$(<$CONNECTION_INFO_ID)
IFS=';' read -ra info <<< "$connection_info"
vm_ip=${info[0]}
vm_ssh_port=${info[1]}

ssh -i /root/.ssh/id_rsa -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ORKA_VM_USER@$vm_ip -p $vm_ssh_port /bin/bash -l < "${1}"
