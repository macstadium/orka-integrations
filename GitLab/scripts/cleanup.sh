#!/bin/bash

set -eu -o pipefail

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${currentDir}/base.sh"

trap system_failure ERR

echo "Cleaning up..."

if [[ -f "$BUILD_ID" ]]; then
    vm_name=$(<"$BUILD_ID")

    echo "Deleting VM '$vm_name'..."

    orka3 vm delete "$vm_name"

    echo "VM deleted."
fi
