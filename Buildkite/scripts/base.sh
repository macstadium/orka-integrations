#!/bin/bash

CONNECTION_INFO_FILE=/tmp/$BUILDKITE_JOB_ID-connection-info

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
