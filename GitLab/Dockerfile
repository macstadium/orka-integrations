ARG BASE_VERSION=alpine

FROM gitlab/gitlab-runner:${BASE_VERSION}

ARG ORKA_CLI_VERSION=4.0.0

RUN apk update && \
    apk --no-cache upgrade openssh-client && \
    apk add --no-cache jq curl openssh

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

COPY scripts /var/custom-executor

# We need to export this environment variable here to ensure that the runner can be automatically deployed into a Kubernetes cluster.
ENV KUBECONFIG=/root/.kube/config

ENTRYPOINT ["dumb-init", "/var/custom-executor/start.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
