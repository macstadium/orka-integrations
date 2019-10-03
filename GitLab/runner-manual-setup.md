# Set up a GitLab Runner manually

This guide explains how to set up a GitLab Runner manually. If you want to set it up automatically, using a Docker container, see [here](custom-executor.md#set-up-a-gitlab-runner).

## Requirements

- GitLab [Runner][runner]
- [jq][jq] - command-line JSON processor used by the provided scripts

## Set up a GitLab Runner

To set up a GitLab Runner manually, you need to:  

1. Install the Runner. You can install a GitLab Runner one of three ways: [manually][manual-install], via a [homebrew installation][homebrew-install], or in a Docker [container][docker-install].
2. [Obtain a token][obtain-token]. The token will be used in **Step 3** to register the newly installed GitLab Runner.
3. [Register][register-runner] the Runner. This is the process that binds the Runner to GitLab.  
**Note**: When asked to enter the executor type, select `custom`.
4. Copy the provided scripts to the Runner machine: [base.sh](scripts/base.sh), [prepare.sh](scripts/prepare.sh), [run.sh](scripts/run.sh), [cleanup.sh](scripts/cleanup.sh).  
**Note**: All scripts should be in the same directory. For example you can add them to `/var/custom-runner`.
5. Verify the scripts can be executed by running `chmod +x path_to_script` in the command line.
6. Update the Runner config file:
    * Verify the `builds_dir` and `cache_dir` settings are present.  
    **Note**: Both the `builds_dir` and `cache_dir` paths must be present on the Orka VM, which will execute the build.
    * Verify the `[runners.custom]` section is available and the `prepare_exec`, `run_exec` and `cleanup_exec` are set to point to the `prepare.sh`, `run.sh` and `cleanup.sh` scripts. 

    **Note**: A template config file is available [here](template-config.md).  
    For information about the location of the file and its contents, see the GitLab Runner [configuration page][config-page] and the Custom executor [configuration page][custom-config-page].
7. Verify [jq][jq] is installed. For more information, see [jq][jq] page.
8. Verify that the private SSH key for connecting to the ephemeral VM is present on the Runner machine under this path `/root/.ssh/id_rsa`. This key was created earlier during the Orka base image setup.

[manual-install]: https://docs.gitlab.com/runner/install/osx.html#manual-installation-official
[homebrew-install]: https://docs.gitlab.com/runner/install/osx.html#homebrew-installation-alternative
[docker-install]: https://docs.gitlab.com/runner/install/docker.html
[obtain-token]: https://docs.gitlab.com/ee/ci/runners/#registering-a-specific-runner-with-a-project-registration-token
[register-runner]: https://docs.gitlab.com/runner/register/index.html
[custom-config-page]: https://docs.gitlab.com/runner/executors/custom.html
[jq]: https://stedolan.github.io/jq/
[runner]: https://docs.gitlab.com/runner/