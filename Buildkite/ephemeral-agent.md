# Using an Еphemeral Buildkite Аgent to Run CI/CD Pipelines in Orka

This guide explains how to set up an ephemeral Buildkite agent in an [Orka by MacStadium][orka] environment. 

The ephemeral agent is used to run a single Buildkite job in a Buildkite [pipeline][pipeline].  
The agent is created before the job execution and deleted once the job completes.

This is achieved by overwriting the Buildkite agent [bootstrap][bootstrap] command of the registered agent.  
This way we create a wrapper agent that instead of executing the Buildkite job locally, spins up an Orka VM and delegates the job to that VM.

## Requirements

- [Orka][orka] VM config
- Buildkite [agent][agent]
- [jq][jq] - command-line JSON processor used by the provided scripts

## Setup overview

1. Set up an Orka VM base image. The image must have SSH enabled and contain an installed Buildkite agent.
2. Set up an Orka VM config using the base image from **Step 1**. The Orka VM config is the container template that the wrapper agent will use to spin up the ephemeral agent.
3. Set up the wrapper agent.

## Set up an Orka VM base image

The Orka VM used as an ephemeral agent needs to have the Buildkite agent installed locally. This is needed to allow the delegation of Buildkite jobs from the wrapper agent.

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
5. Verify that SSH login with a private key is enabled. SSH login is used by the wrapper agent to communicate with the ephemeral agent.
6. On your local machine, run `orka image save`. The command saves the base image in Orka.

## Set up an Orka VM config for the ephemeral agents

To allow the wrapper agent to spin up ephemeral agents in Orka, create an Orka VM config (a container template) that uses the Buildkite-enabled base image you just created.  

You can create an Orka VM config using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up the Buildkite wrapper agent

1. Install and configure a Buildkite agent on a machine that has network visibility to your Orka environment. For more information about how to install and configure a Buildkite agent, see the [instructions][agent-instructions] provided by Buildkite.
2. Copy the provided scripts to the agent machine: [base.sh](scripts/base.sh), [bootstrap.sh](scripts/bootstrap.sh), [run.sh](scripts/run.sh). 
**Note**: All scripts should be in the same directory. For example, you can add them to `/usr/local/var/buildkite-agent/`. Overwrite the existing `bootstrap.sh` file if asked.
3. Make the scripts executable by running `chmod +x path_to_script` in the command line.
4. Copy the provided [pre-exit hook](scripts/pre-exit) to the agent machine. You should add it to the agent hooks directory. It can be found in the `buildkite-agent.cfg` file under the `hooks-path` property. The location of the `buildkite-agent.cfg` varies depending on your OS. For more information, see your [platform's installation instructions][agent-instructions].
5. Make the hook executable by running `chmod +x path_to_hook` in the command line.
6. Verify [jq][jq] is installed. For more information, see [jq][jq] page.
7. Verify that the machine has network visibility to the Orka environment. If the machine is part of the Orka environment, skip this step. You can use any VPN client to connect to the Orka environment. For more information, see your Orka [IP Plan][ip-plan].
8. Verify that the private SSH key for connecting to the ephemeral agent is present on the wrapper machine and added to the ssh-agent. This key was created earlier during the Orka base image setup.
9. Verify that the private SSH keys for the code repositories used by the build job are present on the wrapper machine and added to the ssh-agent.  
**Note** For more information about using multiple SSH keys, see [here][multiple-ssh-keys].

## Buildkite environment variables

The provided scripts expect the following environment variables to be set:

* `ORKA_USER` - User used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_PASSWORD` - Password used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_ENDPOINT` - The Orka endpoint. By default it is `http:/10.10.10.100`
* `ORKA_VM_NAME` - The name of the VM to be deployed. This should match the VM config created [earlier](#set-up-an-orka-vm-config-for-the-ephemeral-agents)
* `ORKA_VM_USER` - User used to SSH to the VM

## Using the Buildkite agent

Once the setup of the Buildkite agent is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

The communication between the Buildkite agent and the Buildkite server is instantiated from the agent.

This means your Orka environment must have visibility to the Buildkite server.

Visibility from the Buildkite server to the Orka environment is not required. 

## Advanced: Additional Buildkite environment variables

By default the wrapper agent and the ephemeral agent share the same Buildkite specific environment variables.  
This means that the wrapper agent and the ephemeral agent will have the same `hook-path` for example.
If you wish to use different environment variables on the ephemeral agent you can set the following optional environment variables:

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
[agent-instructions]: https://buildkite.com/docs/agent/v3/installation
[pipeline]: https://buildkite.com/docs/pipelines
[jq]: https://stedolan.github.io/jq/
[env-variables]: https://buildkite.com/docs/pipelines/environment-variables
[ip-plan]: https://orkadocs.macstadium.com/docs/orka-glossary#section-ip-plan
[bootstrap]: https://buildkite.com/docs/agent/v3/cli-bootstrap
[homebrew]: https://brew.sh/
[multiple-ssh-keys]: https://buildkite.com/docs/agent/v3/ssh-keys#using-multiple-keys-with-ssh-agent