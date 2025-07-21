# Secrets Setup Guide

This document provides detailed instructions for setting up all required secrets for the GitHub Actions CI/CD workflows.

## Overview

The GitHub Actions workflows require several types of secrets:

1. **Azure Credentials**: For accessing AKS clusters
2. **Container Registry Credentials**: For building and pushing custom images
3. **GitHub Tokens**: For accessing GitHub APIs and registries

## Required Secrets

### Azure Credentials

#### Development Environment

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS` | Service principal credentials for dev environment | JSON object |
| `AKS_RESOURCE_GROUP` | AKS resource group name | `my-dev-rg` |
| `AKS_CLUSTER_NAME` | AKS cluster name | `my-dev-cluster` |

#### Staging Environment

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS_STAGING` | Service principal credentials for staging environment | JSON object |
| `AKS_RESOURCE_GROUP_STAGING` | AKS resource group name | `my-staging-rg` |
| `AKS_CLUSTER_NAME_STAGING` | AKS cluster name | `my-staging-cluster` |

#### Production Environment

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS_PROD` | Service principal credentials for production environment | JSON object |
| `AKS_RESOURCE_GROUP_PROD` | AKS resource group name | `my-prod-rg` |
| `AKS_CLUSTER_NAME_PROD` | AKS cluster name | `my-prod-cluster` |

### Container Registry Credentials

#### Azure Container Registry (ACR)

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `ACR_LOGIN_SERVER` | ACR login server URL | `myregistry.azurecr.io` |
| `ACR_USERNAME` | ACR username | `myregistry` |
| `ACR_PASSWORD` | ACR password | `password123` |

#### Docker Hub (Optional)

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub username | `myusername` |
| `DOCKERHUB_TOKEN` | Docker Hub personal access token | `dckr_pat_...` |

### GitHub Configuration

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `GITHUB_TOKEN` | GitHub token for GHCR access | Automatically provided |
| `GITHUB_TOKEN_DEV` | Custom GitHub token for dev environment | `ghp_...` |
| `GITHUB_TOKEN_STAGING` | Custom GitHub token for staging environment | `ghp_...` |
| `GITHUB_TOKEN_PROD` | Custom GitHub token for production environment | `ghp_...` |

## Setup Instructions

### 1. Create Azure Service Principals

#### Development Environment

```bash
# Create service principal for development
az ad sp create-for-rbac \
  --name "github-arc-dev" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{dev-resource-group} \
  --sdk-auth \
  --output json > azure-credentials-dev.json
```

#### Staging Environment

```bash
# Create service principal for staging
az ad sp create-for-rbac \
  --name "github-arc-staging" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{staging-resource-group} \
  --sdk-auth \
  --output json > azure-credentials-staging.json
```

#### Production Environment

```bash
# Create service principal for production
az ad sp create-for-rbac \
  --name "github-arc-prod" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{prod-resource-group} \
  --sdk-auth \
  --output json > azure-credentials-prod.json
```

### 2. Set Up Azure Container Registry

```bash
# Create ACR
az acr create \
  --resource-group {resource-group} \
  --name {acr-name} \
  --sku Basic \
  --admin-enabled true

# Get ACR credentials
az acr credential show --name {acr-name}
```

### 3. Create GitHub Personal Access Tokens

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `admin:org` (Full control of organizations and teams)
   - `write:packages` (Upload packages to GitHub Package Registry)
   - `read:packages` (Download packages from GitHub Package Registry)

### 4. Add Secrets to GitHub Repository

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact name and value

#### Example: Adding Azure Credentials

1. Copy the entire JSON output from the service principal creation
2. Create a new secret named `AZURE_CREDENTIALS`
3. Paste the JSON as the value

#### Example: Adding ACR Credentials

1. Create secret `ACR_LOGIN_SERVER` with value like `myregistry.azurecr.io`
2. Create secret `ACR_USERNAME` with the username from `az acr credential show`
3. Create secret `ACR_PASSWORD` with the password from `az acr credential show`

## Secret Format Examples

### Azure Credentials JSON Format

```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-client-secret",
  "subscriptionId": "12345678-1234-1234-1234-123456789012",
  "tenantId": "12345678-1234-1234-1234-123456789012",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### GitHub Token Format

```
ghp_1234567890abcdef1234567890abcdef12345678
```

### ACR Credentials Format

```
# ACR_LOGIN_SERVER
myregistry.azurecr.io

# ACR_USERNAME
myregistry

# ACR_PASSWORD
password123
```

## Environment-Specific Configurations

### Development Environment

```bash
# Development secrets
AZURE_CREDENTIALS=<dev-service-principal-json>
AKS_RESOURCE_GROUP=dev-runners-rg
AKS_CLUSTER_NAME=dev-runners-cluster
GITHUB_TOKEN_DEV=ghp_dev_token_here
```

### Staging Environment

```bash
# Staging secrets
AZURE_CREDENTIALS_STAGING=<staging-service-principal-json>
AKS_RESOURCE_GROUP_STAGING=staging-runners-rg
AKS_CLUSTER_NAME_STAGING=staging-runners-cluster
GITHUB_TOKEN_STAGING=ghp_staging_token_here
```

### Production Environment

```bash
# Production secrets
AZURE_CREDENTIALS_PROD=<prod-service-principal-json>
AKS_RESOURCE_GROUP_PROD=prod-runners-rg
AKS_CLUSTER_NAME_PROD=prod-runners-cluster
GITHUB_TOKEN_PROD=ghp_prod_token_here
```

## Security Best Practices

### 1. Least Privilege Access

- Create separate service principals for each environment
- Use minimal required permissions
- Regularly rotate credentials

### 2. Secret Rotation

```bash
# Rotate service principal
az ad sp create-for-rbac \
  --name "github-arc-dev-new" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# Update GitHub secret with new credentials
```

### 3. Access Control

- Use Azure RBAC to limit service principal access
- Enable audit logging
- Monitor access patterns

### 4. Network Security

- Use private AKS clusters
- Configure network policies
- Enable Azure Security Center

## Troubleshooting

### Common Issues

#### 1. Authentication Failures

```bash
# Test Azure credentials
az login --service-principal \
  -u <client-id> \
  -p <client-secret> \
  --tenant <tenant-id>

# Test AKS access
az aks get-credentials \
  --resource-group <rg> \
  --name <cluster> \
  --overwrite-existing
```

#### 2. Registry Access Issues

```bash
# Test ACR login
docker login <acr-login-server> \
  -u <username> \
  -p <password>

# Test image push
docker pull hello-world
docker tag hello-world <acr-login-server>/test:latest
docker push <acr-login-server>/test:latest
```

#### 3. GitHub Token Issues

```bash
# Test GitHub token
curl -H "Authorization: token <github-token>" \
  https://api.github.com/user

# Test GHCR access
echo <github-token> | docker login ghcr.io \
  -u <github-username> \
  --password-stdin
```

### Verification Commands

#### Verify Azure Setup

```bash
# Check service principal
az ad sp list --display-name "github-arc-dev"

# Check AKS access
az aks list --resource-group <resource-group>

# Check ACR access
az acr repository list --name <acr-name>
```

#### Verify GitHub Setup

```bash
# Check token permissions
curl -H "Authorization: token <github-token>" \
  https://api.github.com/user

# Check GHCR access
curl -H "Authorization: Bearer <github-token>" \
  https://ghcr.io/v2/
```

## Monitoring and Alerting

### 1. Secret Expiration Monitoring

Set up alerts for:
- Service principal expiration
- GitHub token expiration
- ACR credential rotation

### 2. Access Monitoring

Monitor:
- Service principal usage
- ACR access patterns
- GitHub API usage

### 3. Security Alerts

Configure alerts for:
- Unusual access patterns
- Failed authentication attempts
- Privilege escalation attempts

## References

- [Azure Service Principal Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) 