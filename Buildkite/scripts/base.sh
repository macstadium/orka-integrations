#!/bin/bash

CONNECTION_INFO_FILE=/tmp/$BUILDKITE_JOB_ID-connection-info
SETTINGS_FILE='/var/buildkite/settings.json'

function buildkite-comment {
  echo -ne "\033[90m"
  echo "#" "$@"
  echo -ne "\033[0m"
}

function buildkite-hook {
  HOOK_LABEL="$1"
  HOOK_SCRIPT_PATH="$2"

  echo "~~~ Running $HOOK_LABEL hook"

  if [[ -e "$HOOK_SCRIPT_PATH" ]]; then
    source "$HOOK_SCRIPT_PATH"
  elif [[ "$BUILDKITE_AGENT_DEBUG" == "true" ]]; then
    buildkite-comment "Skipping, no hook script found at: $HOOK_SCRIPT_PATH"
  fi
}

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
    return 1
}

function map_ip {
    local current_ip=${1}
    local result=$current_ip
    if [[ -f "$SETTINGS_FILE" ]]; then
        mappings=($(jq -r '.mappings[] | .private_host, .public_host' $SETTINGS_FILE))
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
