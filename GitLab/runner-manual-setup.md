# Set up a GitLab Runner manually

This guide walks through manual GitLab Runner setup. For automated setup using Docker, see the [Custom executor guide](custom-executor.md#set-up-a-gitlab-runner).

## Prerequisites

Before you begin, ensure you have the following:

- GitLab [Runner][runner] access and installation privileges
- [jq][jq] (command-line JSON processor) - required by the integration scripts
- An Orka base image with SSH key configured
- Administrative access to the machine where the Runner will be installed

## Setup steps

### 1. Install GitLab Runner

Install the Runner using one of these methods:

- [Manual installation][manual-install] (binary)
- [Homebrew installation][homebrew-install] (macOS)
- [Docker container][docker-install]

### 2. Obtain a registration token

Follow GitLab's instructions to [obtain a registration token][obtain-token] for your project or group. You'll use this token in the next step.

### 3. Register the Runner

[Register the Runner][register-runner] with GitLab. When prompted for the executor type, select **custom**.

### 4. Configure the integration scripts

1. Copy these scripts to the Runner machine: [base.sh](scripts/base.sh), [prepare.sh](scripts/prepare.sh), [run.sh](scripts/run.sh), [cleanup.sh](scripts/cleanup.sh)
2. Place all scripts in the same directory (e.g., `/var/custom-runner`)
3. Make the scripts executable: `chmod +x /var/custom-runner/*.sh`

### 5. Configure the Runner

Edit the Runner configuration file to include:

- **Build and cache directories**: Set `builds_dir` and `cache_dir` paths that exist on your Orka VMs
- **Custom executor settings**: Configure the `[runners.custom]` section with paths to your scripts:
  - `prepare_exec` → `prepare.sh`
  - `run_exec` → `run.sh`
  - `cleanup_exec` → `cleanup.sh`

See the [template config file](template-config.md) for reference. For more details on GitLab Runner configuration, consult the [GitLab Runner config documentation][config-page] and [Custom executor documentation][custom-config-page].

### 6. Verify SSH key setup

Confirm that the private SSH key for Orka VM connections is located at `/root/.ssh/id_rsa` on the Runner machine. This key should have been created during your Orka base image setup.

### 7. Test the installation

Verify that jq is installed and accessible by entering: `jq --version`

[manual-install]: https://docs.gitlab.com/runner/install/osx.html#manual-installation-official
[homebrew-install]: https://docs.gitlab.com/runner/install/osx.html#homebrew-installation-alternative
[docker-install]: https://docs.gitlab.com/runner/install/docker.html
[obtain-token]: https://docs.gitlab.com/ee/ci/runners/#registering-a-specific-runner-with-a-project-registration-token
[register-runner]: https://docs.gitlab.com/runner/register/index.html
[config-page]: https://docs.gitlab.com/runner/configuration/
[custom-config-page]: https://docs.gitlab.com/runner/executors/custom.html
[jq]: https://stedolan.github.io/jq/
[runner]: https://docs.gitlab.com/runner/
