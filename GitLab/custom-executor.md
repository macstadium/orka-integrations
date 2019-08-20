# Using a GitLab Custom Executor to Run CI/CD Pipelines in Orka

This guide explains how to set up a GitLab [Custom][custom] executor in a MacStadium [Orka][orka] environment for your GitLab builds.

The Custom executor allows you to run builds on environments not supported natively by the GitLab [Runner][runner] (such as Orka). It also provides the flexibility to define how the environment should be set up and cleaned up.

MacStadium provides Custom executor scripts that can be used to run CI/CD pipelines in an Orka environment.

## Requirements

- GitLab [Runner][runner]
- [jq][jq] - command-line JSON processor used by the provided scripts

## Set up a GitLab Runner

To set up a GitLab Runner, you need to:  

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

## GitLab CI/CD environment variables

The provided scripts expect the following environment variables to be set:

* `ORKA_USER` - User used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_PASSWORD` - Password used to connect to the Orka environment. Created by running `orka user create`
* `ORKA_ENDPOINT` - The Orka endpoint. By default it is `http:/10.10.10.100`
* `ORKA_VM_NAME` - The name of the VM to be deployed
* `ORKA_VM_USER` - User used to SSH to the VM

For more information about GitLab CI/CD environment variables, see [here][env-variables].

## Using the GitLab Custom еxecutor 

Once the setup of the GitLab Runner is finished, you can run your CI/CD pipelines in Orka.

## Connectivity

The communication between the GitLab Runner and the GitLab server is instantiated from the Runner.

This means your Orka environment must have visibility to the GitLab server.

Visibility from the GitLab server to the Orka environment is not required. 

[custom]: https://docs.gitlab.com/runner/executors/custom.html
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
[custom-config-page]: https://docs.gitlab.com/runner/executors/custom.html
[jq]: https://stedolan.github.io/jq/
[config-page]: https://docs.gitlab.com/runner/configuration/advanced-configuration.html
[env-variables]: https://docs.gitlab.com/ee/ci/variables/