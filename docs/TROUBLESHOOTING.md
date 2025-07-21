# Troubleshooting Guide

This guide helps you resolve common issues when deploying and using GitHub Actions Runner Controller on AKS.

## Prerequisites Issues

### kubectl not found
```bash
# Install kubectl
az aks install-cli
```

### Helm not found
```bash
# Install Helm 3
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
```

### Azure CLI not found
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## Authentication Issues

### GitHub Token Issues
**Problem**: Runners fail to register with GitHub

**Symptoms**:
- Runners show as "Pending" status
- Controller logs show authentication errors

**Solutions**:
1. Verify your GitHub token has the correct permissions:
   - `repo` (for repository-level runners)
   - `admin:org` (for organization-level runners)
   - `admin:enterprise` (for enterprise-level runners)

2. Check token format in `config/values.yaml`:
   ```yaml
   github:
     token: "ghp_your_token_here"  # Must start with ghp_
   ```

3. Verify token is not expired

### GitHub App Issues
**Problem**: GitHub App authentication not working

**Solutions**:
1. Ensure all required fields are set:
   ```yaml
   github:
     appId: "123456"
     installationId: "789012"
     privateKey: |
       -----BEGIN RSA PRIVATE KEY-----
       ...
       -----END RSA PRIVATE KEY-----
   ```

2. Verify the GitHub App has the correct permissions:
   - Repository permissions: `Actions` (Read)
   - Organization permissions: `Self-hosted runners` (Read and write)

## Deployment Issues

### Helm Chart Installation Fails
**Problem**: Helm installation times out or fails

**Solutions**:
1. Check cluster connectivity:
   ```bash
   kubectl cluster-info
   ```

2. Verify namespace exists:
   ```bash
   kubectl get namespaces
   ```

3. Check for resource constraints:
   ```bash
   kubectl describe nodes
   ```

4. Increase timeout:
   ```bash
   helm install --timeout 15m github-runner-controller ./charts/controller
   ```

### CRDs Not Installed
**Problem**: Custom Resource Definitions not found

**Symptoms**:
- `kubectl get runnerdeployments` returns "no matches for kind"
- Controller fails to start

**Solutions**:
1. Verify CRDs are installed:
   ```bash
   kubectl get crd | grep actions.summerwind.dev
   ```

2. Reinstall CRDs manually:
   ```bash
   kubectl apply -f charts/controller/templates/crds.yaml
   ```

## Runner Issues

### Runners Not Starting
**Problem**: Runner pods are stuck in Pending or CrashLoopBackOff

**Solutions**:
1. Check pod events:
   ```bash
   kubectl describe pod -n github-runner-system <pod-name>
   ```

2. Check resource availability:
   ```bash
   kubectl describe nodes
   ```

3. Verify node selectors and tolerations match your nodes

4. Check for storage issues:
   ```bash
   kubectl get pvc -n github-runner-system
   ```

### Runners Not Registering
**Problem**: Runners start but don't appear in GitHub

**Solutions**:
1. Check runner logs:
   ```bash
   kubectl logs -n github-runner-system <runner-pod-name>
   ```

2. Verify repository/organization configuration:
   ```yaml
   runnerSet:
     repository: "your-org/your-repo"  # or
     organization: "your-org"
   ```

3. Check runner labels match workflow requirements

### Runners Not Scaling
**Problem**: HPA not scaling runners up or down

**Solutions**:
1. Check HPA status:
   ```bash
   kubectl get hpa -n github-runner-system
   kubectl describe hpa -n github-runner-system <hpa-name>
   ```

2. Verify metrics server is installed:
   ```bash
   kubectl get pods -n kube-system | grep metrics-server
   ```

3. Check resource requests and limits are set correctly

## AKS-Specific Issues

### Azure CNI Issues
**Problem**: Network connectivity issues

**Solutions**:
1. Verify Azure CNI is enabled:
   ```bash
   az aks show --resource-group <rg> --name <cluster> --query networkProfile.networkPlugin
   ```

2. Check subnet configuration:
   ```bash
   az network vnet subnet list --resource-group <rg> --vnet-name <vnet>
   ```

### Storage Issues
**Problem**: Persistent volume claims fail

**Solutions**:
1. Verify storage class exists:
   ```bash
   kubectl get storageclass
   ```

2. Check Azure disk availability in your region

3. Verify storage account permissions

## CI/CD Workflow Issues

### GitHub Actions Workflow Failures

**Symptoms:**
- Workflow jobs failing during deployment
- Authentication errors
- Build failures

**Solutions:**

#### Authentication Issues

Check Azure credentials:
```bash
# Verify service principal
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>

# Check AKS access
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing
```

#### Container Registry Issues

Check registry access:
```bash
# Test ACR login
docker login <acr-login-server> -u <username> -p <password>

# Test image pull
docker pull <acr-login-server>/custom-runner:latest
```

#### Workflow Debugging

Enable debug logging in workflows:
```yaml
- name: Deploy Controller
  run: |
    helm upgrade --install github-runner-controller ./charts/controller \
      -f config/values.yaml \
      --namespace github-runner-system \
      --create-namespace \
      --wait \
      --timeout 10m \
      --debug \
      --set controller.replicas=1
```

#### Common Workflow Issues

1. **Missing Secrets**: Ensure all required secrets are configured in GitHub repository settings
2. **Environment Protection**: Check if environment protection rules are blocking deployments
3. **Resource Limits**: Verify AKS cluster has sufficient resources
4. **Network Issues**: Check if private clusters require additional configuration

### Custom Image Build Failures

**Symptoms:**
- Docker build fails
- Image push fails
- Configuration not updated

**Solutions:**

1. **Test Dockerfile locally**:
   ```bash
   docker build -f docker/custom-runner/Dockerfile docker/custom-runner/
   ```

2. **Check registry permissions**:
   ```bash
   # For ACR
   az acr login --name <acr-name>
   
   # For GHCR
   echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
   ```

3. **Verify image tags**:
   ```bash
   # Check if image exists
   docker pull <registry>/custom-runner:<tag>
   ```

4. **Check workflow permissions**:
   - Ensure workflow has `contents: write` permission for updating config files
   - Verify registry credentials are correct

## Monitoring Issues
### Metrics Not Available
**Problem**: Prometheus metrics not accessible

**Solutions**:
1. Check metrics service:
   ```bash
   kubectl get svc -n github-runner-system | grep metrics
   ```

2. Verify metrics endpoint:
   ```bash
   kubectl port-forward -n github-runner-system svc/github-runner-controller-controller 8080:80
   curl http://localhost:8080/metrics
   ```

## Common Commands

### Check Controller Status
```bash
kubectl get pods -n github-runner-system -l app.kubernetes.io/component=controller
kubectl logs -n github-runner-system -l app.kubernetes.io/component=controller
```

### Check Runner Status
```bash
kubectl get runnerdeployments -n github-runner-system
kubectl get runners -n github-runner-system
kubectl describe runnerdeployment -n github-runner-system <name>
```

### Check HPA Status
```bash
kubectl get hpa -n github-runner-system
kubectl describe hpa -n github-runner-system <name>
```

### Check Events
```bash
kubectl get events -n github-runner-system --sort-by='.lastTimestamp'
```

## Getting Help

If you're still experiencing issues:

1. Check the [official GitHub Actions Runner Controller documentation](https://github.com/actions/actions-runner-controller)
2. Review the [GitHub Issues](https://github.com/actions/actions-runner-controller/issues)
3. Check the [Discussions](https://github.com/actions/actions-runner-controller/discussions)

## Log Collection

When reporting issues, collect the following information:

```bash
# Controller logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=controller --tail=100

# Runner logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=runner --tail=100

# Events
kubectl get events -n github-runner-system --sort-by='.lastTimestamp'

# Resource status
kubectl get all -n github-runner-system
kubectl get runnerdeployments -n github-runner-system
kubectl get runners -n github-runner-system

# Node information
kubectl describe nodes
``` 