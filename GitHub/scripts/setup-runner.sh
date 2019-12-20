#!/bin/bash

set -euo pipefail

github_token=${GITHUB_TOKEN:-}
repository=${REPOSITORY:-}
runner=${RUNNER_NAME:-$(uuidgen)}
version=${RUNNER_VERSION:-"2.163.1"}
type=${RUNNER_RUN_TYPE:-"service"}
work_dir=${RUNNER_WORK_DIR:-"_work"}
deploy_dir=${RUNNER_DEPLOY_DIR:-"$HOME/actions-runner"}

while [[ "$#" -gt 0 ]]
do
case $1 in
    -t|--github_token)
    github_token=$2
    ;;
    -r|--repository)
    repository=$2
    ;;
    -n|--runner_name)
    agent=$2
    ;;
    -v|--runner_version)
    version=$2
    ;;
    -tp|--runner_run_type)
    type=$2
    ;;
    -w|--runner_work_dir)
    work_dir=$2
    ;;
    -d|--runner_deploy_dir)
    deploy_dir=$2
    ;;
esac
shift
done

mkdir $deploy_dir

curl -o $deploy_dir/actions-runner.tar.gz https://githubassets.azureedge.net/runners/$version/actions-runner-osx-x64-$version.tar.gz 
cd $deploy_dir && tar xzf $deploy_dir/actions-runner.tar.gz

$deploy_dir/config.sh --url $repository --token $github_token --name $runner --work $work_dir

if [[ "$type" == "service" ]]; then
    echo "Installing service"
    $deploy_dir/svc.sh install

    if pgrep -qx Finder; then
        echo "Starting service"
        $deploy_dir/svc.sh start
    else
        echo "Cannot start service. No UI session found. Make sure the user is logged in. To enable automatic login, see https://support.apple.com/en-us/HT201476."
        exit -1
    fi
elif [[ "$type" == "command" ]]; then
    echo "Running agent"
    nohup $deploy_dir/run.sh &>/dev/null &
fi
