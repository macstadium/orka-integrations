ARG BASE_VERSION=latest

FROM buildkite/agent:${BASE_VERSION}

ARG ORKA_CLI_VERSION=3.0.0

RUN apk update && \
    apk add jq

RUN wget "https://cli-builds-public.s3.eu-west-1.amazonaws.com/official/${ORKA_CLI_VERSION}/orka3/linux/amd64/orka3.tar.gz" && \
    tar xzf orka3.tar.gz && \
    mv orka3 /usr/local/bin && \
    rm orka3.tar.gz

COPY scripts /buildkite/

ENV BUILDKITE_BOOTSTRAP_SCRIPT_PATH=/buildkite/bootstrap.sh \
    BUILDKITE_BUILD_PATH_SUBAGENT="/tmp/builds" \
    BUILDKITE_HOOKS_PATH_SUBAGENT="/usr/local/etc/buildkite-agent/hooks" \
    BUILDKITE_PLUGINS_PATH_SUBAGENT="/usr/local/var/buildkite-agent/plugins"
