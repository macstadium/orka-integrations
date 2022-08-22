# Using an Еphemeral Buildkite Аgent to Run CI/CD Pipelines in Orka

This guide explains how to set up an ephemeral Buildkite agent in an [Orka by MacStadium][orka] environment. 

The ephemeral agent is used to run a single Buildkite job in a Buildkite [pipeline][pipeline].  
The agent is created before the job execution and deleted once the job completes.

This is achieved by overwriting the Buildkite agent [bootstrap][bootstrap] command of the registered agent.  
This way we create a proxy agent that instead of executing the Buildkite job locally, spins up an Orka VM and delegates the job to that VM.

## Requirements

- [Orka][orka] VM config
- [Docker][docker]

## Setup overview

1. Set up an Orka VM base image. The image must have SSH enabled and contain an installed Buildkite agent.
2. Set up an Orka VM config using the base image from **Step 1**. The Orka VM config is the container template that the proxy agent will use to spin up the ephemeral agent.
3. Set up the proxy agent.

## Set up an Orka VM base image

The Orka VM used as an ephemeral agent needs to have the Buildkite agent installed locally. This is needed to allow the delegation of Buildkite jobs from the proxy agent.

If your Orka environment does not provide a base image pre-configured with a Buildkite agent, you need to create one yourself.

You will later use this base image to create a VM config (a container template) for the ephemeral agent.

1. Set up a new Orka VM. You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].  
2. Connect to the Orka VM using VNC.  
**Note**: The VM IP and VNC ports are displayed once the VM is deployed in Orka.  
3. Verify that [Homebrew][homebrew] is installed on the VM. To install Homebrew, see [here][homebrew].
4. Install the Buildkite agent on the VM by running:  
    ```
    brew tap buildkite/buildkite
    brew install buildkite-agent
    ```
5. Verify that SSH login with a private key is enabled. SSH login is used by the proxy agent to communicate with the ephemeral agent.
6. On your local machine, run `orka image save`. The command saves the base image in Orka.

## Set up an Orka VM config for the ephemeral agents

To allow the proxy agent to spin up ephemeral agents in Orka, create an Orka VM config (a container template) that uses the Buildkite-enabled base image you just created.  

You can create an Orka VM config using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up the Buildkite proxy agent

The recommended way to set up a proxy agent is to use the provided [Dockerfile](Dockerfile).  

On the machine where you want to run the proxy agent container:  

1. Navigate to the [Dockerfile](Dockerfile) directory.
2. Build a Docker image by running `docker build . -t orka-buildkite`.
**Note**: By default the [Dockerfile](Dockerfile) uses the latest Buildkite docker image. If you want to specify another version, use the `BASE_VERSION` build argument: `docker build . -t orka-buildkite --build-args BASE_VERSION=3`.
3. Run a container using the docker image you built and pass your [Buildkite token][agent-token] as a variable.
Verify that the private SSH key for connecting to the ephemeral agent is mounted in the `buildkite-secrets` folder on the container. This key was created earlier during the Orka base image setup.  
Verify that the private SSH keys for the code repositories used by the build job are mounted in the `buildkite-secrets` folder on the container.  
The above is done by running `docker run -v {folder-containing-all-ssh-keys}:/buildkite-secrets -e BUILDKITE_AGENT_TOKEN="{your-token}" orka-buildkite`.
4. Verify that the container has network visibility to the Orka environment. If the machine, running the container, is part of the Orka environment, skip this step. You can use any VPN client to connect to the Orka environment. For more information, see your Orka [IP Plan][ip-plan].

**Note** If you want to set up the proxy agent manually, see [here](proxy-agent-manual-setup.md).

## Buildkite environment variables

The provided scripts expect the following environment variables to be set:

* `ORKA_USER` - User used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_PASSWORD` - Password used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_ENDPOINT` - The Orka endpoint. Usually, it is `http://10.10.10.100`
* `ORKA_VM_NAME` - The name of the VM to be deployed. This should match the VM config created [earlier](#set-up-an-orka-vm-config-for-the-ephemeral-agents)
* `ORKA_VM_USER` - User used to SSH to the VM
* `DEPLOY_TIMEOUT` - Number of seconds to wait for the VM to be deployed

## Advanced configuration

For more information about the advanced settings you can use, see [here](template-settings.md).

## Using the Buildkite agent

Once the setup of the Buildkite agent is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

### Ephemeral agent <-> Buildkite server

The communication between an ephemeral Buildkite agent and the Buildkite server is instantiated from the agent.  

This means your Orka environment must have visibility to the Buildkite server.

Visibility from the Buildkite server to the Orka environment is not required. 

### Proxy agent <-> Orka environment

The Orka environment is behind a firewall.  

This means your proxy agent must have visibility to the Orka environment. You can use any VPN client to connect to the Orka environment. For more information, see your Orka [IP Plan][ip-plan].

## Advanced: Additional Buildkite environment variables

The ephemeral agent accepts the following optional environment variables:

* `BUILDKITE_AGENT_ACCESS_TOKEN_SUBAGENT`
* `BUILDKITE_BUILD_PATH_SUBAGENT`
* `BUILDKITE_HOOKS_PATH_SUBAGENT`
* `BUILDKITE_PLUGINS_PATH_SUBAGENT`
* `BUILDKITE_PLUGINS_ENABLED_SUBAGENT`
* `BUILDKITE_PLUGINS_ENABLED_SUBAGENT`
* `BUILDKITE_PLUGIN_VALIDATION_SUBAGENT`
* `BUILDKITE_LOCAL_HOOKS_ENABLED_SUBAGENT`
* `BUILDKITE_SSH_KEYSCAN_SUBAGENT`
* `BUILDKITE_AGENT_DEBUG_SUBAGENT`

All of the above override the respective Buildkite environment variables without the `_SUBAGENT` suffix.
For example: `BUILDKITE_AGENT_ACCESS_TOKEN_SUBAGENT` overwrites `BUILDKITE_AGENT_ACCESS_TOKEN`.

For more information about Buildkite environment variables, see [here][env-variables].

[orka]: https://orkadocs.macstadium.com/docs/getting-started
[agent]: https://buildkite.com/docs/agent/v3
[cli]: https://orkadocs.macstadium.com/docs/example-cli-workflows
[api]: https://documenter.getpostman.com/view/6574930/S1ETRGzt?version=latest
[quick-start]: https://orkadocs.macstadium.com/docs/quick-start
[pipeline]: https://buildkite.com/docs/pipelines
[env-variables]: https://buildkite.com/docs/pipelines/environment-variables
[ip-plan]: https://orkadocs.macstadium.com/docs/orka-glossary#section-ip-plan
[bootstrap]: https://buildkite.com/docs/agent/v3/cli-bootstrap
[homebrew]: https://brew.sh/
[agent-token]: https://buildkite.com/docs/agent/v3/tokens
[docker]: https://www.docker.com/