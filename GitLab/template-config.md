# GitLab Custom executor template configuration

This is a template configuration that you can use to complete the configuration of your GitLab Custom executor.
For information about the location of the actual configuration file and its contents, see the GitLab Runner [configuration page][config-page].

```toml

# Placeholders
#
# { runner_name } - The name of your runner
# { gitlab_url } - The GitLab URL
# { gitlab_secret } - The GitLab CI/CD secret
# { builds_dir } - The builds directory on the Orka VM. For example /Users/admin/build
# { cache_dir } - The cache directory on the Orka VM. For example /Users/admin/cache
# { prepare_exec_path } - The path to the prepare.sh file. For example /var/custom-runner/prepare.sh
# { run_exec_path } - The path to the run.sh file. For example /var/custom-runner/run.sh
# { cleanup_exec_path } - The path to the cleanup.sh file. For example /var/custom-runner/cleanup.sh
#

concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "{ runner_name }"
  url = "{ gitlab_url }"
  token = "{ gitlab_secret }"
  executor = "custom"
  builds_dir = "{ builds_dir }"
  cache_dir = "{ cache_dir }"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
  [runners.custom]
    prepare_exec = "{ prepare_exec_path }"
    run_exec = "{ run_exec_path }"
    cleanup_exec = "{ cleanup_exec_path }"
```

[config-page]: https://docs.gitlab.com/runner/configuration/advanced-configuration.html
