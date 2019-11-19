# Using a Manually Configured Sinngle Self-Hosted GitHub Actions Runner

This guide explains how to manually set up a self-hosted [GitHub Actions][actions] runner in an [Orka by MacStadium][orka] environment for your GitHub Actions builds. The runner persists over time and GitHub Actions uses it every time you need to run a workflow. 
If you want to set up one runner automatically, see [here](single-self-hosted-runner.md).  
If you want to set up multiple runners automatically, see [here](multiple-self-hosted-runners.md).

## Requirements

- [Orka][orka] VM

## Set up an Orka VM

You can set up an Orka VM using the Orka [CLI][cli] or [REST API][api]. For more information, see the Orka [quick start guide][quick-start].

## Set up a self-hosted GitHub Actions runner

To set up your Orka VM as a GitHub Actions runner, you need to:  

1. Add the runner to a GitHub repository. To do that, follow the [instructions][add-runner] provided by GitHub.
2. (Optional) Configure the runner as a service. This enables automatic start of the runner when the Orka VM starts (for example, after a restart). To do that:  
    1. Follow the [instructions][service-runner] provided by GitHub.  
    **Note**: Connect via VNC to the VM because a UI session is required to start the service.  
    2. Enable automatic login during startup on the Orka VM. To do that, follow these [instructions][auto-login].


## Using the self-hosted GitHub Actions runner

Once the setup of the GitHub runner is finished and as long as the respective Orka VM is up and running, you can run your GitHub Actions workflows in Orka. For more information, see [here][using-runner].

## Checking the status of the self-hosted GitHub Actions runner

To check the status of the runner, follow the [instructions][status-instructions] provided by GitHub.

## Connectivity

The communication between the GitHub runner and GitHub is instantiated from the runner.

This means that your Orka environment must have visibility to GitHub.

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
