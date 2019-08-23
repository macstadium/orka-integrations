# Using a permanent Buildkite agent to Run CI/CD Pipelines in Orka

This guide explains how to set up a permanent Buildkite agent in an [Orka by MacStadium][orka] environment. 

The permanent agent is reused across Buildkite jobs and builds and it allows you to run builds locally on the machine where it is installed.

## Requirements

- [Orka][orka] VM
- Buildkite [agent][agent]
- [jq][jq] - command-line JSON processor used by the provided scripts

## Set up an Orka VM image

You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information about, see the Orka [quick start guide][quick-start].

## Set up a Buildkite agent

To set up a Buildkite agent, see the [instructions][agent-instructions] provided by Buildkite.

## Using the Buildkite agent

Once the setup of the Buildkite agent is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

The communication between the Buildkite agent and the Buildkite server is instantiated from the agent.

This means your Orka environment must have visibility to the Buildkite server.

Visibility from the Buildkite server to the Orka environment is not required. 

[orka]: https://orkadocs.macstadium.com/docs/getting-started
[agent]: https://buildkite.com/docs/agent/v3
[cli]: https://orkadocs.macstadium.com/docs/example-cli-workflows
[api]: https://documenter.getpostman.com/view/6574930/S1ETRGzt?version=latest
[quick-start]: https://orkadocs.macstadium.com/docs/quick-start
[agent-instructions]: https://buildkite.com/docs/agent/v3/installation