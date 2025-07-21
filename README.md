# GitHub Actions Runner Controller for AKS

This repository contains Helm charts and configurations for deploying the **official Microsoft-supported GitHub Actions Runner Controller** to Azure Kubernetes Service (AKS) with support for multiple runner scale sets using different runner images.

> **Note**: This repository uses the official Microsoft-supported GitHub Actions Runner Controller from [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller), not the community-maintained version.

## Overview

The GitHub Actions Runner Controller allows you to automatically scale GitHub Actions runners in Kubernetes. This setup provides:

- **Main Controller**: Manages the core runner controller infrastructure
- **Standard Runners**: Default runner scale set with standard runner image
- **Custom Runners**: Additional scale sets with different runner images for specific workloads

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AKS Cluster                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Runner Controller│  │ Standard Runners│  │ Custom Runners│ │
│  │                 │  │ Scale Set       │  │ Scale Sets   │ │
│  │ - Manager       │  │ - Default Image │  │ - Custom Imgs │ │
│  │ - Webhook       │  │ - Auto-scaling  │  │ - Specialized │ │
│  │ - Metrics       │  │ - Workloads     │  │ - Workloads   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Azure CLI
- kubectl
- Helm 3.x
- AKS cluster with appropriate permissions
- GitHub Personal Access Token with `repo` and `admin:org` scopes

## Quick Start

### Option 1: Manual Deployment

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd github-arc
   ```

2. **Configure your environment**:
   ```bash
   cp config/values.yaml.example config/values.yaml
   # Edit config/values.yaml with your GitHub token and repository details
   ```

3. **Deploy the controller**:
   ```bash
   helm install github-runner-controller ./charts/controller \
     -f config/values.yaml \
     --namespace github-runner-system \
     --create-namespace
   ```

4. **Deploy standard runners**:
   ```bash
   helm install standard-runners ./charts/runner-set \
     -f config/values.yaml \
     -f config/standard-runners.yaml \
     --namespace github-runner-system
   ```

5. **Deploy custom runners** (optional):
   ```bash
   helm install custom-runners ./charts/runner-set \
     -f config/values.yaml \
     -f config/custom-runners.yaml \
     --namespace github-runner-system
   ```

### Option 2: Automated Deployment with GitHub Actions

1. **Set up required secrets** in your GitHub repository:
   - Azure credentials for each environment
   - Container registry credentials
   - GitHub tokens

2. **Configure environments** in GitHub repository settings:
   - `development`
   - `staging` 
   - `production`

3. **Deploy using workflows**:
   - Go to Actions tab
   - Run "Deploy GitHub Actions Runner Controller" workflow
   - Run "Deploy Runner Scale Sets" workflow

For detailed CI/CD setup instructions, see [CI/CD Setup Guide](docs/CI_CD_SETUP.md).

## Configuration

### Main Configuration (`config/values.yaml`)

- GitHub authentication settings
- Controller configuration
- Default runner settings
- AKS-specific configurations

### Runner Scale Sets

- **Standard Runners** (`config/standard-runners.yaml`): Default runners for general workloads
- **Custom Runners** (`config/custom-runners.yaml`): Specialized runners with custom images

## Monitoring

Access the controller dashboard:
```bash
kubectl port-forward -n github-runner-system svc/github-runner-controller 8080:80
```

Then visit: http://localhost:8080

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details. 