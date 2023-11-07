# Using a GitLab Shell Executor to Run CI/CD Pipelines in Orka

This guide explains how to set up a GitLab [Shell][shell] executor in a MacStadium [Orka][orka] environment for your GitLab builds. 

The Shell executor allows you to run builds locally on the machine where the GitLab [Runner][runner] is installed.

## Requirements

- [Orka][orka] VM
- GitLab [Runner][runner]

## Set up an Orka VM

You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up a GitLab Runner

To set up a GitLab Runner, you need to:  

1. Install the Runner. You can install a GitLab Runner one of three ways: [manually][manual-install], via a [homebrew installation][homebrew-install], or in a Docker [container][docker-install].
2. [Obtain a token][obtain-token]. The token will be used in **Step 3** to register the newly installed GitLab Runner.
3. [Register][register-runner] the Runner. This is the process that binds the Runner to GitLab.  
**Note**: When asked to enter the executor type, select `shell`.

## Using the GitLab Shell executor

Once the setup of the GitLab Runner is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

The communication between the GitLab Runner and the GitLab server is instantiated from the Runner.

This means your Orka environment must have visibility to the GitLab server.

Visibility from the GitLab server to the Orka environment is not required. 

[shell]: https://docs.gitlab.com/runner/executors/shell.html
[orka]: https://orkadocs.macstadium.com/docs/getting-started
[cli]: https://orkadocs.macstadium.com/docs/example-cli-workflows
[api]: https://documenter.getpostman.com/view/6574930/S1ETRGzt?version=latest
[quick-start]: https://orkadocs.macstadium.com/docs/quick-start
[runner]: https://docs.gitlab.com/runner/
[manual-install]: https://docs.gitlab.com/runner/install/osx.html#manual-installation-official
[homebrew-install]: https://docs.gitlab.com/runner/install/osx.html#homebrew-installation-alternative
[docker-install]: https://docs.gitlab.com/runner/install/docker.html
[obtain-token]: https://docs.gitlab.com/ee/ci/runners/#registering-a-specific-runner-with-a-project-registration-token
[register-runner]: https://docs.gitlab.com/runner/register/index.html
