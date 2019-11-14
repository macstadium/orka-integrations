# Using a self-hosted GitHub Actions runner

This guide explains how to automatically set up a single self-hosted [GitHub Actions][actions] runner in a MacStadium [Orka][orka] environment for your GitHub Actions builds.  
If you want to set it up multiple runners automatically, see [here](multiple-self-hosted-runners.md).

## Requirements

- [Orka][orka] VM

## Set up an Orka VM

You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].  
*Optional:* If you want to enable automatic start of the runner when the machine starts, you need to enable automatic login during startup. To do that, follow the [instructions][auto-login].

## Set up a self-hosted GitHub Actions runner

To set up a GitHub Actions runner, you need to:  

1. Obtain a GitHub token. 
    * Follow steps **1** to **5** in the [instructions][add-runner] provided by GitHub.
    * You can find your token in the `Configure` section right after the `--token` flag.
2. Connect to the Orka VM you want to configure as a GitHub Actions runner.
3. Download the [setup-runner.sh](scripts/setup-runner.sh) file.
4. Run the script by providing the following arguments:
    * `-t` or `--github_token` - The GitHub token you obtained in **Step 1**.
    * `-r` or `--repository` - The URL of the GitHub repository you want to attach the runner to.
    * `-n` or `--runner_name` - The name of the runner. By default it is a custom GUID.
    * `-v` or `--runner_version` - The version of the runner. By default it is `2.160.2`.
    * `-tp` or `--runner_run_type` - One of `command` and `service`. Choose `service` if you want the runner to start automatically when the VM starts. It is `command` by default.  
    **Note** If you choose `service` you need to enable automatic login during startup. To do that, follow the [instructions][auto-login].
    * `-w` or `--runner_work_dir` - Runner working directory. By default it is `_work` under the runner installation directory.
    * `-d` or `--runner_deploy_dir` - Runner installation directory. By default it is `actions-runner` under the user home directory.

## Environment variables

You can also use environment variables instead of passing arguments to the [setup-runner.sh](scripts/setup-runner.sh) script. These are the available variables:

* GITHUB_TOKEN
* REPOSITORY
* RUNNER_NAME
* RUNNER_VERSION
* RUNNER_RUN_TYPE
* RUNNER_WORK_DIR
* RUNNER_DEPLOY_DIR

## Using the self-hosted GitHub Actions runner

Once the setup of the GitHub runner is finished, you can run your GitHub Actions workflows in Orka. For more information, see [here][using-runner].

## Checking the status of the self-hosted GitHub Actions runner

To check the status of the runner, follow the [instructions][status-instructions] provided by GitHub.

## Connectivity

The communication between the GitHub runner and GitHub is instantiated from the runner.

This means your Orka environment must have visibility to GitHub.

Visibility from GitHub to the Orka environment is not required. 

[orka]: https://orkadocs.macstadium.com/docs/getting-started
[cli]: https://orkadocs.macstadium.com/docs/example-cli-workflows
[api]: https://documenter.getpostman.com/view/6574930/S1ETRGzt?version=latest
[quick-start]: https://orkadocs.macstadium.com/docs/quick-start
[actions]: https://github.com/features/actions
[add-runner]: https://help.github.com/en/actions/automating-your-workflow-with-github-actions/adding-self-hosted-runners
[service-runner]: https://help.github.com/en/actions/automating-your-workflow-with-github-actions/configuring-the-self-hosted-runner-application-as-a-service
[auto-login]: https://support.apple.com/en-us/HT201476
[using-runner]: https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-self-hosted-runners-in-a-workflow
[status-instructions]: https://help.github.com/en/actions/automating-your-workflow-with-github-actions/checking-the-status-of-self-hosted-runners
