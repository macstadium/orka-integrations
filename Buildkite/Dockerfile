ARG BASE_VERSION=latest

FROM buildkite/agent:${BASE_VERSION}

RUN apk update && \
    apk add jq

COPY scripts /buildkite/

ENV BUILDKITE_BOOTSTRAP_SCRIPT_PATH=/buildkite/bootstrap.sh \
    BUILDKITE_BUILD_PATH_SUBAGENT="/tmp/builds" \
    BUILDKITE_HOOKS_PATH_SUBAGENT="/usr/local/etc/buildkite-agent/hooks" \
    BUILDKITE_PLUGINS_PATH_SUBAGENT="/usr/local/var/buildkite-agent/plugins"
