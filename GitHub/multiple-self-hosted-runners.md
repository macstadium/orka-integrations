# Using a self-hosted GitHub Actions runner

This guide explains how to automatically set up multiple self-hosted [GitHub Actions][actions] runners in a MacStadium [Orka][orka] environment for your GitHub Actions builds.  
If you want to set it up one runner automatically, see [here](single-self-hosted-runner.md).

## Requirements

- [Orka][orka] VM config
- [jq][jq] - command-line JSON processor used by the provided scripts

## Setup overview

1. Set up an Orka VM base image. The image must have SSH enabled. Optionally, it could have automatic login enabled.
2. Set up an Orka VM config using the base image from **Step 1**. The Orka VM config is the container template that the runner script will use to spin up GitHub Actions runners.
3. Run the setup script.

## Set up an Orka VM base image

If your Orka environment does not provide a base image pre-configured with SSH enabled, you need to create one yourself.

You will later use this base image to create a VM config (a container template) for the runner.

1. Set up a new Orka VM. You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].  
2. Connect to the Orka VM using VNC.  
**Note**: The VM IP and VNC ports are displayed once the VM is deployed in Orka.  
3. Verify that SSH login with a private key is enabled. SSH login is used by the proxy agent to set up the runner.
4. (Optional) Enable automatic login during startup. This enables automatic start of the runner when machine starts. To do that, follow the [instructions][auto-login].
5. On your local machine, run `orka image save`. The command saves the base image in Orka.

## Set up an Orka VM config for the runner

To allow the setup script to spin up GitHub runners in Orka, create an Orka VM config (a container template) that uses the SSH-enabled base image you just created.  

You can create an Orka VM config using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up multiple self-hosted GitHub Actions runners

To set up multiple GitHub Actions runner, you need to:  

1. Obtain a GitHub token. 
    * Follow steps **1** to **5** in the [instructions][add-runner] provided by GitHub.
    * You can find your token in the `Configure` section right after the `--token` flag.
2. On a machine that has connectivity to your Orka environment:
    * Install [jq][jq] - command-line JSON processor used by the provided scripts
    * Download [multiple-runners.sh](scripts/multiple-runners.sh) and [setup-runner.sh](scripts/setup-runner.sh) files in the same directory.
    * Run the [multiple-runners.sh](scripts/multiple-runners.sh) script by providing the following arguments
        * `-u` or `--orka_user` - User used to connect to the Orka environment. Created by running `orka user create`.
        * `-p` or `--orka_password` - Password used to connect to the Orka environment. Created by running `orka user create`.
        * `-e` or `--orka_endpoint` - The Orka endpoint. Usually, it is `http://10.10.10.100`.
        * `-v` or `--orka_vm_name` - The name of the VM to be deployed. This should match the VM config created [earlier](#set-up-an-orka-vm-config-for-the-runner).
        * `-vu` or `--orka_vm_user` - User used to SSH to the VM.
        * `-c` or `--agent_count` - The number of runners to be created. By default it is `1`.
        * `-s` or `--ssh_key_location` - The location on your local machine of the SSH key used to connect to the Orka VMs. By default it is `~/.ssh/id_rsa`.
        * `-t` or `--github_token` - The GitHub token you obtained in **Step 1**.
        * `-r` or `--repository` - The URL of the GitHub repository you want to attach the runner to.
        * `-rv` or `--runner_version` - The version of the runner. By default it is `2.160.2`.
        * `-tp` or `--runner_run_type` - One of `command` and `service`. Choose `service` if you want the runner to start automatically when the VM starts. It is `command` by default.  
        **Note** If you choose `service` you need to enable automatic login during startup. To do that, follow the [instructions][auto-login].

## Environment variables

You can also use environment variables instead of passing arguments to the [setup-runner.sh](scripts/setup-runner.sh) script. These are the available variables:

* ORKA_USER
* ORKA_PASSWORD
* ORKA_ENDPOINT
* ORKA_VM_NAME
* ORKA_VM_USER
* AGENT_COUNT
* SSH_KEY_LOCATION
* GITHUB_TOKEN
* REPOSITORY
* RUNNER_NAME
* RUNNER_VERSION
* RUNNER_RUN_TYPE
* RUNNER_WORK_DIR
* RUNNER_DEPLOY_DIR

## Using the self-hosted GitHub Actions runner

Once the setup of the GitHub runners are finished, you can run your GitHub Actions workflows in Orka. For more information, see [here][using-runner].

## Checking the status of the self-hosted GitHub Actions runner

To check the status of any the runners, follow the [instructions][status-instructions] provided by GitHub.

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
[jq]: https://stedolan.github.io/jq/
