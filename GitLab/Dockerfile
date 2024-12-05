ARG BASE_VERSION=alpine

FROM gitlab/gitlab-runner:${BASE_VERSION}

ARG ORKA_CLI_VERSION=3.0.0

RUN apk update && \
    apk add jq curl openssh

RUN wget "https://cli-builds-public.s3.eu-west-1.amazonaws.com/official/${ORKA_CLI_VERSION}/orka3/linux/amd64/orka3.tar.gz" && \
    tar xzf orka3.tar.gz && \
    mv orka3 /usr/local/bin && \
    rm orka3.tar.gz

COPY scripts /var/custom-executor

# We need to export this environment variable here to ensure that the runner can be automatically deployed into a Kubernetes cluster.
ENV KUBECONFIG=/root/.kube/config

ENTRYPOINT ["dumb-init", "/var/custom-executor/start.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
