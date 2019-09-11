# Set up the Buildkite wrapper agent manually

This guide explains how to set up a Buildkite wrapper agent manually. If you want to set it up automatically, using a Docker container, see [here](ephemeral-agent.md#set-up-the-buildkite-wrapper-agent).

1. Install and configure a Buildkite agent on a machine that has network visibility to your Orka environment. For more information about how to install and configure a Buildkite agent, see the [instructions][agent-instructions] provided by Buildkite.
2. Copy the provided scripts to the agent machine: [base.sh](scripts/base.sh), [bootstrap.sh](scripts/bootstrap.sh), [run.sh](scripts/run.sh). 
**Note**: All scripts should be in the same directory. For example, you can add them to `/usr/local/var/buildkite-agent/`. Overwrite the existing `bootstrap.sh` file if asked.
3. Make the scripts executable by running `chmod +x path_to_script` in the command line.
4. Copy the provided [pre-exit hook](scripts/hooks/pre-exit) to the agent machine. You should add it to the agent hooks directory. It can be found in the `buildkite-agent.cfg` file under the `hooks-path` property. The location of the `buildkite-agent.cfg` varies depending on your OS. For more information, see your [platform's installation instructions][agent-instructions].
5. Make the hook executable by running `chmod +x path_to_hook` in the command line.
6. Verify [jq][jq] is installed. For more information, see the [jq][jq] page.
7. Verify that the machine has network visibility to the Orka environment. If the machine is part of the Orka environment, skip this step. You can use any VPN client to connect to the Orka environment. For more information, see your Orka [IP Plan][ip-plan].
8. Verify that the private SSH key for connecting to the ephemeral agent is present on the wrapper machine and added to the ssh-agent. This key was created earlier during the Orka base image setup.
9. Verify that the private SSH keys for the code repositories used by the build job are present on the wrapper machine and added to the ssh-agent.  
**Note** For more information about using multiple SSH keys, see [here][multiple-ssh-keys].

[agent-instructions]: https://buildkite.com/docs/agent/v3/installation
[jq]: https://stedolan.github.io/jq/
[multiple-ssh-keys]: https://buildkite.com/docs/agent/v3/ssh-keys#using-multiple-keys-with-ssh-agent
[ip-plan]: https://orkadocs.macstadium.com/docs/orka-glossary#section-ip-plan
