ARG BASE_VERSION=latest

FROM buildkite/agent:${BASE_VERSION}

ARG ORKA_CLI_VERSION=4.0.0

RUN apk update && \
    apk add jq

# Orka 4.0 renamed the CLI from orka3 to orka and moved its artifacts to the orka/ path.
# Install the matching build as `orka`, with an `orka3` symlink for older custom scripts.
RUN set -e; \
    major="${ORKA_CLI_VERSION%%.*}"; \
    if [ "$major" -ge 4 ]; then name=orka; else name=orka3; fi; \
    wget "https://cli-builds-public.s3.eu-west-1.amazonaws.com/official/${ORKA_CLI_VERSION}/${name}/linux/amd64/${name}.tar.gz"; \
    tar xzf "${name}.tar.gz"; \
    mv "${name}" /usr/local/bin/orka; \
    ln -s orka /usr/local/bin/orka3; \
    rm "${name}.tar.gz"

COPY scripts /buildkite/

ENV BUILDKITE_BOOTSTRAP_SCRIPT_PATH=/buildkite/bootstrap.sh \
    BUILDKITE_BUILD_PATH_SUBAGENT="/tmp/builds" \
    BUILDKITE_HOOKS_PATH_SUBAGENT="/usr/local/etc/buildkite-agent/hooks" \
    BUILDKITE_PLUGINS_PATH_SUBAGENT="/usr/local/var/buildkite-agent/plugins"
