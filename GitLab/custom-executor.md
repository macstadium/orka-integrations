# Using a GitLab Custom Executor to Run CI/CD Pipelines in Orka

This guide explains how to set up a GitLab [Custom][custom] executor in a MacStadium [Orka][orka] environment for your GitLab builds.

The Custom executor allows you to run builds on environments not supported natively by the GitLab [Runner][runner] (such as Orka). It also provides the flexibility to define how the environment should be set up and cleaned up.

MacStadium provides Custom executor scripts that can be used to run CI/CD pipelines in an Orka environment.
The Custom executor spins up ephemeral Mac machines, which will execute the CI/CD jobs.

## Requirements

- [Orka][orka] VM config
- [Docker][docker]

## Setup overview

1. Set up an Orka VM base image. The image must have SSH enabled.
2. Set up an Orka VM config using the base image from **Step 1**. The Orka VM config is the container template that Custom executor will use to spin up ephemeral Mac machines.
3. Set up the GitLab Runner.

## Set up an Orka VM base image

The Orka VM is used by the Custom executor to run CI/CD jobs.

If your Orka environment does not provide a base image pre-configured with SSH login with a private key enabled, you need to create one yourself.

You will later use this base image to create a VM config (a container template) for the ephemeral agent.

1. Set up a new Orka VM. You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].
2. Connect to the Orka VM using SSH or VNC.  
   **Note**: The VM IP and the SSH and VNC ports are displayed once the VM is deployed in Orka.
3. Verify that SSH login with a private key is enabled. SSH login is used by the Custom executor to communicate with the Orka VM.  
   **Note**: The private ssh key must not have password as the GitLab Runner will not be able to load it.
4. On your local machine, run `orka3 vm <VM_NAME> commit`. The command saves the base image in Orka.

## Set up an Orka VM config for the ephemeral agents

To allow the Custom executor to spin up ephemeral VMs in Orka, create an Orka VM config (a container template) that uses the SSH-enabled base image you just created.

You can create an Orka VM config using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up a GitLab Runner

The recommended wey to set up a GitLab Runner is to use the provided [Dockerfile](Dockerfile).

To do that:

1. Navigate to the [Dockerfile](Dockerfile) directory.
2. Build a Docker image by running `docker build . -t orka-gitlab`.
   **Note**: The Dockerfile supports the Alpine GitLab Runner docker images. By default the [Dockerfile](Dockerfile) uses the latest GitLab Alpine docker image. If you want to specify another version, use the `BASE_VERSION` build argument: `docker build . -t orka-gitlab --build-arg BASE_VERSION=alpine-bleeding`.
3. [Obtain a token][obtain-token]. The token will be used in the next step to register the newly installed GitLab Runner.
4. [Register][register-runner] and start the Runner. This is the process that binds the Runner to GitLab. To register the Runner, run the following command:  
   `docker run -e TOKEN=${REGISTRATION_TOKEN} orka-gitlab`. Replace the placeholders with the correct values.
5. Verify that the container has network visibility to the Orka environment. If the machine, running the container, is part of the Orka environment, skip this step. You can use any VPN client to connect to the Orka environment. For more information, see your Orka [IP Plan][ip-plan].

**Note** If you want to set up the Runner manually, see [here](runner-manual-setup.md).

## GitLab CI/CD environment variables

The provided scripts expect the following environment variables to be set:

- `ORKA_TOKEN` - User authentication to connect to the Orka environment. Created by running `orka3 user get-token` or `orka3 serviceaccount token <service-account>`.
- `ORKA_ENDPOINT` - The Orka endpoint. Usually, it is `http://10.221.188.20`.
- `ORKA_CONFIG_NAME` - The name of the VM config to be deployed.
- `ORKA_VM_NAME_PREFIX` - The prefix of the generated VM name. Defaults to `gl-runner`.
- `ORKA_VM_USER` - User used to SSH to the VM. Defaults to `admin`.
- `ORKA_SSH_KEY_FILE` - The private SSH key contents to use when connecting to the VM. This key was created earlier during the Orka base image setup.
- `VM_DEPLOYMENT_ATTEMPTS` - The number of attempts the executor tries to deploy a VM before it fails. Defaults to `1`. Note - GitLab automatically retries 3 times. This env var allows additional retry attempts.

For more information about GitLab CI/CD environment variables, see [here][env-variables].

## Advanced configuration

For more information about the advanced settings you can use, see [here](template-settings.md).

## Using the GitLab Custom executor

Once the setup of the GitLab Runner is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

The communication between the GitLab Runner and the GitLab server is instantiated from the Runner.

This means your Orka environment must have visibility to the GitLab server.

Visibility from the GitLab server to the Orka environment is not required.

[custom]: https://docs.gitlab.com/runner/executors/custom.html
[orka]: https://support.macstadium.com/hc/en-us/articles/29904434271387-Orka-Overview
[cli]: https://support.macstadium.com/hc/en-us/articles/42514244203419-Orka3-CLI-Overview-Configuration
[api]: https://macstadium.github.io/orka-api-docs/
[quick-start]: https://support.macstadium.com/hc/en-us/articles/28347375974555-Orka3-CLI-Quick-Start
[docker]: https://www.docker.com/
[obtain-token]: https://docs.gitlab.com/ee/ci/runners/#registering-a-specific-runner-with-a-project-registration-token
[register-runner]: https://docs.gitlab.com/runner/register/index.html
[env-variables]: https://docs.gitlab.com/ee/ci/variables/
[ip-plan]: https://support.macstadium.com/hc/en-us/articles/28230867289883-IP-Plan
[runner]: https://docs.gitlab.com/runner/
