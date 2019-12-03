#!/bin/bash

BUILD_ID="runner-$CUSTOM_ENV_CI_RUNNER_ID-project-$CUSTOM_ENV_CI_PROJECT_ID-concurrent-$CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID"
CONNECTION_INFO_ID=$BUILD_ID-connection-info

BUILDKITE_AGENT_ACCESS_TOKEN=${BUILDKITE_AGENT_ACCESS_TOKEN_SUBAGENT:-$BUILDKITE_AGENT_ACCESS_TOKEN}

ORKA_USER=${ORKA_USER:-$CUSTOM_ENV_ORKA_USER}
ORKA_PASSWORD=${ORKA_PASSWORD:-$CUSTOM_ENV_ORKA_PASSWORD}
ORKA_ENDPOINT=${ORKA_ENDPOINT:-$CUSTOM_ENV_ORKA_ENDPOINT}
ORKA_VM_NAME=${ORKA_VM_NAME:-$CUSTOM_ENV_ORKA_VM_NAME}
ORKA_VM_USER=${ORKA_VM_USER:-$CUSTOM_ENV_ORKA_VM_USER}

function valid_ip {
    local ip=${1-}

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.' read -ra ip <<< "$ip"
        IFS=$OIFS

        if [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]; then
            return 0
        fi
    fi
    return -1
}