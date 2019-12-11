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

function report_timeout {
    if [ $? -eq 28 ]; then
        echo "Curl opertion timed out. Exiting..."
    fi
}