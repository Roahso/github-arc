# CI/CD Setup with GitHub Actions

This document explains how to set up and use the GitHub Actions workflows for deploying GitHub Actions Runner Controller to AKS.

## Overview

The repository includes several GitHub Actions workflows that provide:

- **Automated Deployment**: Deploy controller and runner scale sets to different environments
- **Custom Image Building**: Build and push custom runner images to container registries
- **Validation**: Validate Helm charts, YAML files, and security scans
- **Flexibility**: Support for multiple environments and custom configurations

## Workflows

### 1. Deploy Controller (`deploy-controller.yml`)

Deploys the GitHub Actions Runner Controller to AKS clusters.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

**Environments:**
- **Development**: Automatic deployment on `develop` branch
- **Staging**: Automatic deployment on `main` branch
- **Production**: Manual deployment only

**Features:**
- Helm chart validation
- Kubernetes manifest validation
- Multi-environment support
- Deployment verification

### 2. Deploy Runner Scale Sets (`deploy-runners.yml`)

Deploys runner scale sets with support for custom images.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

**Runner Types:**
- **Standard Runners**: Use official Microsoft runner images
- **Custom Runners**: Use custom-built images with additional tools

**Features:**
- Automatic custom image building
- Multiple runner scale sets
- Environment-specific configurations
- Auto-scaling support

### 3. Build Custom Runner Image (`build-custom-image.yml`)

Builds and pushes custom runner images to container registries.

**Triggers:**
- Push to `main` or `develop` branches (Dockerfile changes)
- Pull requests to `main` branch
- Manual workflow dispatch

**Supported Registries:**
- Azure Container Registry (ACR)
- GitHub Container Registry (GHCR)
- Docker Hub

**Features:**
- Multi-platform builds (linux/amd64, linux/arm64)
- Automatic tagging
- Configuration updates
- Registry flexibility

### 4. Validate Configuration (`validate.yml`)

Validates all configurations and performs security scans.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

**Validations:**
- Helm chart linting
- Kubernetes manifest validation
- YAML syntax checking
- Dockerfile validation
- Security vulnerability scanning
- Dependency checking

## Required Secrets

### Azure Credentials

```bash
# Development Environment
AZURE_CREDENTIALS
AKS_RESOURCE_GROUP
AKS_CLUSTER_NAME

# Staging Environment
AZURE_CREDENTIALS_STAGING
AKS_RESOURCE_GROUP_STAGING
AKS_CLUSTER_NAME_STAGING

# Production Environment
AZURE_CREDENTIALS_PROD
AKS_RESOURCE_GROUP_PROD
AKS_CLUSTER_NAME_PROD
```

### Container Registry Credentials

```bash
# Azure Container Registry
ACR_LOGIN_SERVER
ACR_USERNAME
ACR_PASSWORD

# Docker Hub (optional)
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

### GitHub Configuration

```bash
# GitHub token for GHCR access
GITHUB_TOKEN  # Automatically provided by GitHub Actions
```

## Setup Instructions

### 1. Configure Azure Credentials

Create service principals for each environment:

```bash
# Development
az ad sp create-for-rbac --name "github-arc-dev" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# Staging
az ad sp create-for-rbac --name "github-arc-staging" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# Production
az ad sp create-for-rbac --name "github-arc-prod" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

### 2. Configure Container Registry

#### Azure Container Registry

```bash
# Create ACR
az acr create --resource-group {resource-group} --name {acr-name} --sku Basic

# Get credentials
az acr credential show --name {acr-name}
```

#### GitHub Container Registry

No additional setup required - uses `GITHUB_TOKEN` automatically.

#### Docker Hub

Create a personal access token in Docker Hub settings.

### 3. Add Secrets to GitHub Repository

1. Go to your repository settings
2. Navigate to "Secrets and variables" → "Actions"
3. Add all required secrets

### 4. Configure Environments

Set up environment protection rules:

1. Go to repository settings
2. Navigate to "Environments"
3. Create environments: `development`, `staging`, `production`
4. Configure protection rules as needed

## Usage Examples

### Deploy Controller

```bash
# Automatic deployment on push to develop/main
git push origin develop

# Manual deployment
# Go to Actions tab → Deploy GitHub Actions Runner Controller → Run workflow
```

### Deploy Runner Scale Sets

```bash
# Deploy standard runners
# Go to Actions tab → Deploy Runner Scale Sets → Run workflow
# Select: Environment: dev, Runner set: standard

# Deploy custom runners
# Go to Actions tab → Deploy Runner Scale Sets → Run workflow
# Select: Environment: dev, Runner set: custom

# Deploy all runners
# Go to Actions tab → Deploy Runner Scale Sets → Run workflow
# Select: Environment: dev, Runner set: all
```

### Build Custom Image

```bash
# Build and push to ACR
# Go to Actions tab → Build Custom Runner Image → Run workflow
# Select: Registry: acr, Image name: custom-runner

# Build and push to GHCR
# Go to Actions tab → Build Custom Runner Image → Run workflow
# Select: Registry: ghcr, Image name: custom-runner
```

## Customization

### Adding New Runner Scale Sets

1. Create a new configuration file:

```yaml
# config/my-custom-runners.yaml
runnerSet:
  name: "my-custom-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "my-custom"
  image: "my-registry/my-custom-runner:latest"
  replicas: 2
  # ... other configurations
```

2. Update the deployment workflow to include the new configuration.

### Environment-Specific Configurations

Create environment-specific value files:

```yaml
# config/values-dev.yaml
github:
  token: ${{ secrets.GITHUB_TOKEN_DEV }}

# config/values-staging.yaml
github:
  token: ${{ secrets.GITHUB_TOKEN_STAGING }}

# config/values-prod.yaml
github:
  token: ${{ secrets.GITHUB_TOKEN_PROD }}
```

### Custom Image Variants

Create different Dockerfile variants:

```dockerfile
# docker/python-runner/Dockerfile
FROM ghcr.io/actions/actions-runner:latest

# Install Python-specific tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    # ... other Python tools
```

## Monitoring and Troubleshooting

### Workflow Status

Monitor workflow execution in the GitHub Actions tab:

1. Go to "Actions" tab in your repository
2. Select the workflow you want to monitor
3. View logs and status for each job

### Common Issues

#### Authentication Failures

```bash
# Check Azure credentials
az login --service-principal -u {app-id} -p {password} --tenant {tenant-id}

# Check AKS access
az aks get-credentials --resource-group {rg} --name {cluster} --overwrite-existing
```

#### Image Build Failures

```bash
# Test Dockerfile locally
docker build -f docker/custom-runner/Dockerfile docker/custom-runner/

# Check registry access
docker login {registry-url}
```

#### Deployment Failures

```bash
# Check Helm chart
helm lint charts/controller/
helm template test charts/controller/ -f config/values.yaml

# Check Kubernetes resources
kubectl get pods -n github-runner-system
kubectl describe pod {pod-name} -n github-runner-system
```

### Logs and Debugging

#### Enable Debug Logging

Add debug flags to workflows:

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

#### View Detailed Logs

```bash
# Controller logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=controller

# Runner logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=runner

# Events
kubectl get events -n github-runner-system --sort-by='.lastTimestamp'
```

## Security Considerations

### Secret Management

- Use GitHub Secrets for sensitive data
- Rotate credentials regularly
- Use least-privilege access for service principals
- Enable audit logging

### Image Security

- Scan images for vulnerabilities
- Use specific image tags instead of `latest`
- Sign images when possible
- Use private registries for custom images

### Network Security

- Use private AKS clusters
- Configure network policies
- Enable Azure Security Center
- Monitor network traffic

## Best Practices

### Workflow Organization

1. **Separate Concerns**: Keep controller and runner deployments separate
2. **Environment Isolation**: Use different environments for dev/staging/prod
3. **Manual Production**: Require manual approval for production deployments
4. **Rollback Strategy**: Implement rollback procedures

### Configuration Management

1. **Version Control**: Keep all configurations in Git
2. **Environment Parity**: Maintain consistency across environments
3. **Secret Rotation**: Implement automated secret rotation
4. **Documentation**: Keep configuration documentation updated

### Monitoring and Alerting

1. **Health Checks**: Implement comprehensive health checks
2. **Metrics Collection**: Collect and monitor metrics
3. **Alerting**: Set up alerts for failures and issues
4. **Logging**: Implement structured logging

## Support

For issues with the CI/CD workflows:

1. Check the workflow logs in GitHub Actions
2. Review the troubleshooting guide
3. Check the official GitHub Actions documentation
4. Open an issue in the repository

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Documentation](https://helm.sh/docs/)
- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [GitHub Actions Runner Controller](https://github.com/actions/actions-runner-controller) 