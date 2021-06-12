#!/bin/bash

BUILD_ID="runner-$CUSTOM_ENV_CI_RUNNER_ID-project-$CUSTOM_ENV_CI_PROJECT_ID-concurrent-$CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID"
export CONNECTION_INFO_ID=$BUILD_ID-connection-info

ORKA_USER=${ORKA_USER:-$CUSTOM_ENV_ORKA_USER}
ORKA_PASSWORD=${ORKA_PASSWORD:-$CUSTOM_ENV_ORKA_PASSWORD}
ORKA_ENDPOINT=${ORKA_ENDPOINT:-$CUSTOM_ENV_ORKA_ENDPOINT}
ORKA_VM_NAME=${ORKA_VM_NAME:-$CUSTOM_ENV_ORKA_VM_NAME}
ORKA_VM_USER=${ORKA_VM_USER:-$CUSTOM_ENV_ORKA_VM_USER}

SETTINGS_FILE='/var/custom-executor/settings.json'

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
    return 255
}

function system_failure {
    if [ $? -eq 28 ]; then
        echo "Curl opertion timed out. Exiting..."
    fi
    exit "$SYSTEM_FAILURE_EXIT_CODE"
}

function revoke_token {
    local token=${1}
    local orka_endpoint=${2}
    echo "Revoking token..."
    token_response=$(curl -s -m 60 -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X DELETE "$orka_endpoint/token")
    echo "Token revoked: $token_response"
}

function map_ip {
    local current_ip=${1}
    local result=$current_ip
    if [[ -f "$SETTINGS_FILE" ]]; then
        mappings=("$(jq -r '.mappings[] | .private_host, .public_host' "$SETTINGS_FILE")")
        for ((i = 0; i < ${#mappings[@]}; i+=2)); do
            if [[ "$current_ip" == "${mappings[$i]}" ]]; then
                result=${mappings[$((i + 1))]}
                break
            fi
        done
    fi
    echo "$result"
    return 0
}
