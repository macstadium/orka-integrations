# Troubleshooting the GitLab Orka Integration

This guide covers common issues and solutions when using the GitLab [Custom executor][custom] with [Orka][orka].

## Authentication issues

### Error: "unauthorized" or "401"

**Symptoms:**
- VM deployment fails with authentication errors
- `orka3` commands return "unauthorized"

**Causes:**
- `ORKA_TOKEN` is invalid or expired

**Solutions:**

1. Generate a new service account token:
   ```bash
   orka3 serviceaccount token <service-account-name>
   ```

2. Update the token in GitLab CI/CD settings:
   - Go to Settings > CI/CD > Variables
   - Update `ORKA_TOKEN` with the new token

**Note:** Service account tokens are valid for 1 year by default. For custom duration, use `--duration` flag.

### Error: "config not found" or "no such host"

**Symptoms:**
- CLI commands fail before authentication
- "dial tcp: lookup" errors

**Causes:**
- `ORKA_ENDPOINT` is not set or malformed
- Network connectivity issues to Orka API

**Solutions:**

1. Verify the endpoint format in GitLab CI/CD Variables (include protocol, no trailing slash):
   ```
   # Correct format
   http://10.221.188.20

   # Incorrect formats
   10.221.188.20          # Missing protocol
   http://10.221.188.20/  # Trailing slash
   ```

2. If the endpoint is correct but commands still fail, see [Runner cannot reach Orka endpoint](#runner-cannot-reach-orka-endpoint) for connectivity troubleshooting.

## VM deployment failures

### Error: "VM deployment failed"

**Symptoms:**
- prepare.sh exits with "VM deployment failed"
- Deployment attempts exhausted

**Causes:**
- `ORKA_CONFIG_NAME` doesn't exist or is misspelled
- No available nodes with sufficient resources

**Solutions:**

1. If the error says "config does not exist", check the spelling of `ORKA_CONFIG_NAME` in your GitLab CI/CD Variables. Create the config if needed:
   ```bash
   orka3 vm-config create <config-name> --image <image-name> --cpu <count>
   ```

2. Check available node resources:
   ```bash
   orka3 node list -o wide
   ```

3. Increase deployment attempts by setting the environment variable in `.gitlab-ci.yml`:
   ```yaml
   variables:
     VM_DEPLOYMENT_ATTEMPTS: "3"
   ```

### Error: "Invalid ip" or "Invalid port"

**Symptoms:**
- VM deploys but connection info extraction fails
- "Invalid ip: null" in logs

**Causes:**
- VM deployment returned unexpected JSON format
- VM is in a failed state

**Solutions:**

1. Deploy a VM manually and inspect the output:
   ```bash
   orka3 vm deploy test-vm --config "$ORKA_CONFIG_NAME" -o json
   ```

2. Check VM status:
   ```bash
   orka3 vm list test-vm -o wide
   ```

3. Delete the test VM after inspection:
   ```bash
   orka3 vm delete test-vm
   ```

## SSH connection issues

### Error: "Waited 30 seconds for sshd to start"

**Symptoms:**
- VM deploys successfully
- SSH connection times out after 30 seconds

**Causes:**
- SSH is not enabled on the base image
- SSH key not configured on the VM
- VM is still booting

**Solutions:**

Since the runner automatically deletes failed VMs, deploy a VM manually to troubleshoot:

1. Deploy a test VM:
   ```bash
   orka3 vm deploy test-debug --config "$ORKA_CONFIG_NAME"
   ```

2. Get connection details:
   ```bash
   orka3 vm list test-debug
   ```

3. Connect via Screen Sharing (VNC) to check:
   - System Preferences > Sharing > Remote Login is enabled
   - Your public key is in `~/.ssh/authorized_keys`

4. Test SSH manually:
   ```bash
   ssh -i ~/.ssh/orka_deployment_key -p <PORT> admin@<VM_IP> "echo ok"
   ```

5. Clean up:
   ```bash
   orka3 vm delete test-debug
   ```

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
   ssh-keygen -y -f /path/to/key
   ```

2. If the key has a passphrase, generate a new one without:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/orka_key -N ""
   ```

3. Verify `ORKA_VM_USER` in GitLab CI/CD Variables matches the user on the VM (default: `admin`).

4. Deploy a test VM and verify the public key is in `~/.ssh/authorized_keys`.

## Environment variable issues

### Error: "unbound variable" or blank values

**Symptoms:**
- Script fails immediately
- Variables are empty

**Causes:**
- Required environment variables not configured in GitLab

**Solutions:**

Verify all required variables are set in GitLab CI/CD settings (Settings > CI/CD > Variables):

| Variable | Required | Description |
|----------|----------|-------------|
| `ORKA_TOKEN` | Yes | Service account token |
| `ORKA_ENDPOINT` | Yes | Orka API URL |
| `ORKA_CONFIG_NAME` | Yes | VM config template name |
| `ORKA_SSH_KEY_FILE` | Yes | Private SSH key contents |
| `ORKA_VM_USER` | No | SSH user (default: `admin`) |
| `ORKA_VM_NAME_PREFIX` | No | VM name prefix (default: `gl-runner`) |
| `VM_DEPLOYMENT_ATTEMPTS` | No | Retry count (default: `1`) |

For sensitive variables like `ORKA_TOKEN` and `ORKA_SSH_KEY_FILE`, enable the "Masked" option.

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

1. Test connectivity from the runner environment:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" "$ORKA_ENDPOINT/api/v1/cluster-info"
   ```

2. If using VPN, verify your connection using your [IP plan][ip-plan] details.

3. For Docker-based runners, ensure the container has network access to the Orka endpoint.

### IP mapping issues

**Symptoms:**
- VM deploys but SSH connects to wrong IP
- "No route to host" errors

**Causes:**
- Private/public IP mismatch
- settings.json not configured for IP mapping

**Solutions:**

If your network requires IP mapping, create `/var/custom-executor/settings.json`:
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

See [template-settings.md](template-settings.md) for configuration details.

## Job execution issues

### Build script fails

**Symptoms:**
- Job fails during run.sh
- Error is from your CI/CD script, not the integration

**Note:** The integration distinguishes between:
- **Build failures**: Your script failed (returns script exit code)
- **System failures**: Infrastructure failed (returns exit code 1)

If your build script fails, the issue is in your script, not the integration. Test your script on a standalone Orka VM.

### Job hangs or times out

**Symptoms:**
- Job runs but never completes
- GitLab times out the job

**Causes:**
- Long-running process without output
- SSH connection dropped

**Solutions:**

1. For long jobs, add periodic output to prevent GitLab timeout.

2. Consider breaking long jobs into smaller stages.

3. Increase GitLab job timeout in project settings if needed.

## Cleanup issues

### Orphaned VMs

**Symptoms:**
- VMs remain after job completion

**Causes:**
- Runner crashed before cleanup
- Network issue during cleanup

**Solutions:**

Delete orphaned VMs manually:
```bash
orka3 vm delete <vm-name>
```

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
[masked-variables]: https://docs.gitlab.com/ee/ci/variables/#mask-a-cicd-variable
[runner-logs]: https://docs.gitlab.com/runner/faq/#how-can-i-get-a-debug-log
[support]: https://support.macstadium.com/
