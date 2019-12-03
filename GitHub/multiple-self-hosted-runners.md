# Using Multiple Automatically Configured Self-Hosted GitHub Actions Runners

This guide explains how to automatically set up multiple self-hosted [GitHub Actions][actions] runners in an [Orka by MacStadium][orka] environment for your GitHub Actions builds. The runners persist over time and GitHub Actions uses them every time you need to run a workflow. 
If you want to set it up one runner automatically, see [here](single-self-hosted-runner.md).
If you want to set up one runner manually, see [here](self-hosted-runner-manually.md).

## Requirements

- [Orka][orka] VM config
- [jq][jq] - command-line JSON processor used by the provided scripts

## Setup overview

1. Set up an Orka VM base image. The image must have SSH enabled. If you want to run the runner as a service, enable automatic login.
2. Set up an Orka VM config using the base image from **Step 1**. The Orka VM config is the container template that the runner script will use to spin up GitHub Actions runners.
3. Run the setup script.

## Set up an Orka VM base image

If your Orka environment does not provide a base image with enabled SSH, you need to create one yourself.

You will later use this base image to create a VM config (a container template) for the runner.

1. Set up a new Orka VM. You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].  
2. Connect to the Orka VM using VNC.  
**Note**: You can get the IP and VNC port by running `orka vm list`.  
3. Verify that SSH login with a private key is enabled. SSH login is used to set up the runner.
4. (Optional) Enable automatic login during startup. This enables automatic start of the runner when the VM starts. To do that, follow these [instructions][auto-login].
5. On your local machine, run `orka image save`. The command saves the base image in Orka.

## Set up an Orka VM config for the runner

To allow the setup script to spin up GitHub runners in Orka, create an Orka VM config (a container template) that uses an SSH-enabled base image (for example, the one you just created).  

You can create an Orka VM config using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up multiple self-hosted GitHub Actions runners

To set up multiple GitHub Actions runner, you need to:  

1. Obtain a GitHub token. 
    * Follow steps **1** to **5** in the [instructions][add-runner] provided by GitHub.
    * You can find your token in the `Configure` section right after the `--token` flag.
2. On a machine that has connectivity to your Orka environment:
    * Install [jq][jq] - a command-line JSON processor used by the provided scripts.
    * Download [multiple-runners.sh](scripts/multiple-runners.sh), [setup-runner.sh](scripts/setup-runner.sh) and [base.sh](scripts/base.sh) files in the same directory.
    * Run the [multiple-runners.sh](scripts/multiple-runners.sh) script and provide the following arguments
        * `-u` or `--orka_user` - (Required) User used to authenticate with the Orka environment. Created by running `orka user create`.
        * `-p` or `--orka_password` - (Required) Password used to authenticate with the Orka environment. Created by running `orka user create`.
        * `-e` or `--orka_endpoint` - (Required) The Orka endpoint. Usually, `http://10.10.10.100` OR `http://10.221.188.100`.
        * `-v` or `--orka_vm_name` - (Required) The name of the VM config to be deployed. This should match the VM config created [earlier](#set-up-an-orka-vm-config-for-the-runner).
        * `-vu` or `--orka_vm_user` - (Required) User used to SSH to the VM.
        * `-c` or `--runner_count` - (Optional) The number of runners to be created. If not specified, defaults to `1`.
        * `-s` or `--ssh_key_location` - (Required) The location on your local machine of the SSH key used to connect to the Orka VMs. By default it is `~/.ssh/id_rsa`.
        * `-t` or `--github_token` - (Required) The GitHub token you obtained in **Step 1**.
        * `-r` or `--repository` - (Required) The URL of the GitHub repository you want to attach the runner to.
        * `-rv` or `--runner_version` - (Optional) The version of the runner. If not specified, defaults to `2.160.2`.
        * `-tp` or `--runner_run_type` - (Optional) One of `command` or `service`. Choose `service` if you want the runner to start automatically when the VM starts. Choose `command` if you want to manually start the runner every time the VM starts. If not specified, defaults to `service`.  
        **Note** If you don't specify or you set to `service`, you need to enable automatic login during startup. To do that, follow these [instructions][auto-login].

## Environment variables

You can also use environment variables instead of passing arguments to the [multiple-runners.sh](scripts/multiple-runners.sh) script. These are the available variables:

* `ORKA_USER`
* `ORKA_PASSWORD`
* `ORKA_ENDPOINT`
* `ORKA_VM_NAME`
* `ORKA_VM_USER`
* `RUNNER_COUNT`
* `SSH_KEY_LOCATION`
* `GITHUB_TOKEN`
* `REPOSITORY`
* `RUNNER_NAME`
* `RUNNER_VERSION`
* `RUNNER_RUN_TYPE`

## Using the self-hosted GitHub Actions runner

Once the setup of the GitHub runners is finished and as long as the respective Orka VMs are up and running, you can run your GitHub Actions workflows in Orka. For more information, see [here][using-runner].

## Checking the status of the self-hosted GitHub Actions runners

To check the status of any the runners, follow the [instructions][status-instructions] provided by GitHub.

## Connectivity

The communication between any GitHub runner and GitHub is instantiated from the runner.

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
[jq]: https://stedolan.github.io/jq/
