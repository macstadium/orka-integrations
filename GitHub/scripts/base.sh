#!/bin/bash

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

function handle_exit {
    local token=${1}
    local orka_endpoint=${2}

    if [ $? -eq 28 ]; then
        echo "Curl opertion timed out. Exiting..."
    fi

    api_version=$(curl -s $orka_endpoint/health-check | jq '.api_version' | sed 's/[\.\"]//g')

    if [ $api_version -lt 210 ]; then
        echo "Revoking token..."
        token_response=$(curl -s -m 60 -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X DELETE $orka_endpoint/token)
        echo "Token revoked: $token_response"
    fi
}

function map_ip {
    local current_ip=${1}
    local settings_file=${2:-}
    local result=$current_ip
    if [[ -f "$settings_file" ]]; then
        mappings=($(jq -r '.mappings[] | .private_host, .public_host' $settings_file))
        for ((i = 0; i < ${#mappings[@]}; i+=2)); do
            if [[ "$current_ip" == "${mappings[$i]}" ]]; then
                result=${mappings[$((i + 1))]}
                break
            fi
        done
    fi

    echo $result

    return 0
}
