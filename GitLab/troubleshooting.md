# Troubleshooting the GitLab Orka Integration

This guide covers common issues and solutions when using the GitLab [Custom executor][custom] with [Orka][orka].

## Quick diagnostics

Before diving into specific issues, run these checks:

```bash
# Verify Orka CLI is installed and accessible
orka3 version

# Test Orka authentication
orka3 config set --api-url "$ORKA_ENDPOINT"
orka3 user set-token "$ORKA_TOKEN"
orka3 vm list

# Verify jq is installed (required by scripts)
jq --version

# Test SSH key validity
ssh-keygen -l -f ~/.ssh/orka_deployment_key
```

## Authentication issues

### Error: "unauthorized" or "401"

**Symptoms:**
- VM deployment fails with authentication errors
- `orka3` commands return "unauthorized"

**Causes:**
- `ORKA_TOKEN` is invalid, expired, or not set
- `ORKA_ENDPOINT` is incorrect

**Solutions:**

1. Verify the token is set correctly:
   ```bash
   echo "$ORKA_TOKEN" | head -c 20
   ```

2. Generate a new token:
   ```bash
   # For user authentication
   orka3 login
   orka3 user get-token

   # For service accounts (CI/CD recommended)
   orka3 serviceaccount token <service-account-name>
   ```

3. Verify the endpoint is correct:
   ```bash
   curl -s "$ORKA_ENDPOINT/api/v1/health" | jq .
   ```

**Note:** Tokens expire after 1 hour. For CI/CD pipelines, use [service accounts][serviceaccount] which provide longer-lived tokens.

### Error: "config not found" or "no such host"

**Symptoms:**
- CLI commands fail before authentication
- "dial tcp: lookup" errors

**Causes:**
- `ORKA_ENDPOINT` is not set or malformed
- Network connectivity issues to Orka API

**Solutions:**

1. Verify the endpoint format (include protocol, no trailing slash):
   ```bash
   # Correct
   export ORKA_ENDPOINT="http://10.221.188.20"

   # Incorrect
   export ORKA_ENDPOINT="10.221.188.20"
   export ORKA_ENDPOINT="http://10.221.188.20/"
   ```

2. Test network connectivity:
   ```bash
   curl -v "$ORKA_ENDPOINT/api/v1/health"
   ```

3. If using VPN, verify your connection. See your [IP plan][ip-plan] for connection details.

## VM deployment failures

### Error: "VM deployment failed"

**Symptoms:**
- prepare.sh exits with "VM deployment failed"
- Deployment attempts exhausted

**Causes:**
- `ORKA_CONFIG_NAME` doesn't exist or is misspelled
- No available nodes with sufficient resources
- Base image not found

**Solutions:**

1. Verify the VM config exists:
   ```bash
   orka3 vm-config list | grep "$ORKA_CONFIG_NAME"
   ```

2. Check available node resources:
   ```bash
   orka3 node list -o wide
   ```

3. Verify the base image exists:
   ```bash
   orka3 image list
   ```

4. Increase deployment attempts by setting the environment variable:
   ```yaml
   # In .gitlab-ci.yml
   variables:
     VM_DEPLOYMENT_ATTEMPTS: "3"
   ```

### Error: "Invalid ip" or "Invalid port"

**Symptoms:**
- VM deploys but connection info extraction fails
- "Invalid ip: null" in logs

**Causes:**
- VM deployment returned unexpected JSON format
- jq parsing error
- VM is in a failed state

**Solutions:**

1. Manually test deployment and inspect output:
   ```bash
   orka3 vm deploy test-vm --config "$ORKA_CONFIG_NAME" -o json | jq .
   ```

2. Verify jq is correctly installed:
   ```bash
   echo '{"ip":"10.0.0.1"}' | jq -r '.ip'
   ```

3. Check VM status after deployment:
   ```bash
   orka3 vm list -o wide
   ```

## SSH connection issues

### Error: "Waited 30 seconds for sshd to start"

**Symptoms:**
- VM deploys successfully
- SSH connection times out after 30 seconds

**Causes:**
- SSH is not enabled on the base image
- SSH key mismatch
- Network/firewall blocking SSH port
- VM is still booting

**Solutions:**

1. Verify SSH is enabled on your base image:
   - Connect to a VM via VNC
   - Check System Preferences > Sharing > Remote Login

2. Verify the SSH key matches:
   ```bash
   # On Runner: get public key fingerprint
   ssh-keygen -l -f ~/.ssh/orka_deployment_key

   # On VM: check authorized_keys
   cat ~/.ssh/authorized_keys
   ```

3. Test SSH connectivity manually:
   ```bash
   ssh -i ~/.ssh/orka_deployment_key -p <PORT> admin@<VM_IP> "echo ok"
   ```

4. Increase the wait time by modifying prepare.sh (line 66) if VMs need more boot time.

### Error: "Permission denied (publickey)"

**Symptoms:**
- SSH connection is refused
- "Permission denied" in logs

**Causes:**
- SSH key has a passphrase (not supported)
- Wrong SSH user
- SSH key not in VM's authorized_keys

**Solutions:**

1. Verify the SSH key has no passphrase:
   ```bash
   # This should NOT prompt for a passphrase
   ssh-keygen -y -f ~/.ssh/orka_deployment_key
   ```

2. If the key has a passphrase, generate a new one without:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/orka_key -N ""
   ```

3. Verify the `ORKA_VM_USER` matches the user on the VM (default: `admin`):
   ```yaml
   variables:
     ORKA_VM_USER: "admin"
   ```

4. Ensure the public key is in the VM's `~/.ssh/authorized_keys`.

### Error: "Host key verification failed"

**Symptoms:**
- SSH fails with host key errors
- "REMOTE HOST IDENTIFICATION HAS CHANGED" warnings

**Causes:**
- Known hosts file has stale entries
- Strict host key checking enabled

**Solutions:**

The scripts handle this automatically by updating known_hosts, but if issues persist:

1. Clear the known hosts for the problematic IP:
   ```bash
   ssh-keygen -R "[<VM_IP>]:<PORT>"
   ```

2. The scripts use `StrictHostKeyChecking=no` during initial connection, so this should not block ephemeral VMs.

## Environment variable issues

### Error: "unbound variable" or blank values

**Symptoms:**
- Script fails immediately
- Variables are empty

**Causes:**
- Required environment variables not set
- Variables not exported correctly in GitLab CI/CD

**Solutions:**

1. Verify all required variables are set in your GitLab CI/CD settings or `.gitlab-ci.yml`:

| Variable | Required | Description |
|----------|----------|-------------|
| `ORKA_TOKEN` | Yes | Authentication token |
| `ORKA_ENDPOINT` | Yes | Orka API URL |
| `ORKA_CONFIG_NAME` | Yes | VM config template name |
| `ORKA_SSH_KEY_FILE` | Yes | Private SSH key contents |
| `ORKA_VM_USER` | No | SSH user (default: `admin`) |
| `ORKA_VM_NAME_PREFIX` | No | VM name prefix (default: `gl-runner`) |
| `VM_DEPLOYMENT_ATTEMPTS` | No | Retry count (default: `1`) |

2. For sensitive variables, use GitLab CI/CD [masked variables][masked-variables]:
   - Go to Settings > CI/CD > Variables
   - Add variables with "Masked" option enabled

3. Verify variables are accessible in your job:
   ```yaml
   test_variables:
     script:
       - echo "Endpoint: $ORKA_ENDPOINT"
       - echo "Config: $ORKA_CONFIG_NAME"
   ```

## Network and connectivity issues

### Runner cannot reach Orka endpoint

**Symptoms:**
- "Connection refused" or "Connection timed out"
- curl to endpoint fails

**Causes:**
- Runner is not on the same network as Orka
- VPN not connected
- Firewall blocking traffic

**Solutions:**

1. Verify network connectivity:
   ```bash
   ping -c 3 $(echo "$ORKA_ENDPOINT" | sed 's|http://||')
   curl -v "$ORKA_ENDPOINT/api/v1/health"
   ```

2. If using VPN, verify your connection using your [IP plan][ip-plan] details.

3. For Docker-based runners, ensure the container has network access:
   ```bash
   docker run --rm orka-gitlab curl -v "$ORKA_ENDPOINT/api/v1/health"
   ```

### IP mapping issues

**Symptoms:**
- VM deploys but SSH connects to wrong IP
- "No route to host" errors

**Causes:**
- Private/public IP mismatch
- settings.json not configured for IP mapping

**Solutions:**

1. If your network requires IP mapping, create `/var/custom-executor/settings.json`:
   ```json
   {
     "mappings": [
       {
         "private_host": "10.221.188.100",
         "public_host": "203.0.113.100"
       }
     ]
   }
   ```

2. See [template-settings.md](template-settings.md) for configuration details.

## Job execution issues

### Error: Build script fails but not a system failure

**Symptoms:**
- Job fails during run.sh
- Error is from your CI/CD script, not the integration

**Causes:**
- Your build script has errors
- Missing dependencies on the VM
- Path or environment issues on the VM

**Solutions:**

1. The integration correctly distinguishes between:
   - **Build failures**: Your script failed (exit code from script)
   - **System failures**: Infrastructure failed (exit code 1)

2. Check your build script runs correctly on a standalone Orka VM.

3. Ensure required tools are installed on your base image.

### Error: Job hangs or times out

**Symptoms:**
- Job runs but never completes
- GitLab times out the job

**Causes:**
- Long-running process without output
- SSH connection dropped
- VM became unresponsive

**Solutions:**

1. The scripts use SSH keep-alive (60-second intervals for 60 minutes):
   ```
   ServerAliveInterval=60
   ServerAliveCountMax=60
   ```

2. For very long jobs, consider:
   - Breaking into smaller jobs
   - Adding periodic output to prevent timeout
   - Increasing GitLab job timeout in project settings

## Cleanup issues

### Orphaned VMs

**Symptoms:**
- VMs remain after job completion
- `orka3 vm list` shows old runner VMs

**Causes:**
- Runner crashed before cleanup
- cleanup.sh failed
- Network issue during cleanup

**Solutions:**

1. Manually delete orphaned VMs:
   ```bash
   # List VMs with runner prefix
   orka3 vm list | grep "gl-runner"

   # Delete specific VM
   orka3 vm delete <vm-name>

   # Delete all runner VMs (use with caution)
   orka3 vm list -o json | jq -r '.[].name' | grep "gl-runner" | xargs -I {} orka3 vm delete {}
   ```

2. Consider setting up a periodic cleanup job to remove stale VMs.

## Getting help

If you're still experiencing issues:

1. Check the [Orka documentation][orka-docs] for platform-specific guidance
2. Review GitLab Runner [logs][runner-logs]: `gitlab-runner --debug run`
3. Contact [MacStadium Support][support] with:
   - Error messages and logs
   - Environment details (Runner version, Orka version)
   - Steps to reproduce

[custom]: https://docs.gitlab.com/runner/executors/custom.html
[orka]: https://support.macstadium.com/hc/en-us/articles/29904434271387-Orka-Overview
[orka-docs]: https://support.macstadium.com/hc/en-us
[ip-plan]: https://support.macstadium.com/hc/en-us/articles/28230867289883-IP-Plan
[serviceaccount]: https://support.macstadium.com/hc/en-us/articles/28347450648987-Orka3-Service-Accounts
[masked-variables]: https://docs.gitlab.com/ee/ci/variables/#mask-a-cicd-variable
[runner-logs]: https://docs.gitlab.com/runner/faq/#how-can-i-get-a-debug-log
[support]: https://support.macstadium.com/
