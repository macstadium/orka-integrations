#!/bin/bash
set -euo pipefail

PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

buildkite-agent bootstrap
