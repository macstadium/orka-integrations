ARG BASE_VERSION=alpine

FROM gitlab/gitlab-runner:${BASE_VERSION}

RUN apk update && \
    apk add jq curl openssh

COPY scripts /var/custom-executor

ENV RUNNER_BUILDS_DIR="/tmp/builds" \
    RUNNER_CACHE_DIR="/tmp/cache" \
    CUSTOM_PREPARE_EXEC="/var/custom-executor/prepare.sh" \
    CUSTOM_RUN_EXEC="/var/custom-executor/run.sh" \
    CUSTOM_CLEANUP_EXEC="/var/custom-executor/cleanup.sh"
