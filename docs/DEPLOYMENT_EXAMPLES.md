# Deployment Examples

This document provides practical examples for deploying GitHub Actions Runner Controller in different scenarios.

## Deployment Methods

### Method 1: Manual Deployment

#### 1. Single Repository Runners

Deploy runners for a specific repository:

```yaml
# config/single-repo-runners.yaml
runnerSet:
  name: "my-repo-runners"
  repository: "my-org/my-repo"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
  replicas: 2
  image: "ghcr.io/actions/actions-runner:latest"
```

Deploy:
```bash
./scripts/deploy.sh deploy-controller
./scripts/deploy.sh deploy-standard -f config/single-repo-runners.yaml
```

### Method 2: Automated Deployment with GitHub Actions

#### 1. Deploy Controller

1. Go to your repository's Actions tab
2. Select "Deploy GitHub Actions Runner Controller"
3. Click "Run workflow"
4. Choose environment (dev/staging/prod)
5. Click "Run workflow"

#### 2. Deploy Runner Scale Sets

1. Go to your repository's Actions tab
2. Select "Deploy Runner Scale Sets"
3. Click "Run workflow"
4. Choose environment and runner set type:
   - **Standard**: Deploy standard runners only
   - **Custom**: Deploy custom runners only
   - **All**: Deploy both standard and custom runners
5. Click "Run workflow"

#### 3. Build Custom Runner Image

1. Go to your repository's Actions tab
2. Select "Build Custom Runner Image"
3. Click "Run workflow"
4. Choose registry and image name
5. Click "Run workflow"

## Basic Deployment Examples

### 2. Organization-Wide Runners

Deploy runners for an entire organization:

```yaml
# config/org-runners.yaml
runnerSet:
  name: "org-runners"
  organization: "my-organization"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "org-wide"
  replicas: 5
  image: "ghcr.io/actions/actions-runner:latest"
```

Deploy:
```bash
./scripts/deploy.sh deploy-controller
./scripts/deploy.sh deploy-standard -f config/org-runners.yaml
```

## Advanced Scenarios

### 3. Multi-Environment Runners

Deploy different runner sets for different environments:

```yaml
# config/dev-runners.yaml
runnerSet:
  name: "dev-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "dev"
  replicas: 2
  image: "ghcr.io/actions/actions-runner:latest"
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
```

```yaml
# config/prod-runners.yaml
runnerSet:
  name: "prod-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "prod"
  replicas: 3
  image: "ghcr.io/actions/actions-runner:latest"
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 8Gi
```

Deploy:
```bash
./scripts/deploy.sh deploy-controller
./scripts/deploy.sh deploy-standard -f config/dev-runners.yaml
./scripts/deploy.sh deploy-standard -f config/prod-runners.yaml
```

### 4. GPU-Enabled Runners

Deploy runners with GPU support for ML workloads:

```yaml
# config/gpu-runners.yaml
runnerSet:
  name: "gpu-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "gpu"
    - "ml"
  replicas: 1
  image: "my-registry/gpu-runner:latest"
  resources:
    requests:
      cpu: 2000m
      memory: 4Gi
      nvidia.com/gpu: 1
    limits:
      cpu: 8000m
      memory: 16Gi
      nvidia.com/gpu: 1
  nodeSelector:
    accelerator: nvidia
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
```

Deploy:
```bash
./scripts/deploy.sh deploy-custom -f config/gpu-runners.yaml
```

### 5. Windows Runners

Deploy Windows runners alongside Linux runners:

```yaml
# config/windows-runners.yaml
runnerSet:
  name: "windows-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "windows"
    - "x64"
  replicas: 2
  image: "my-registry/windows-runner:latest"
  nodeSelector:
    kubernetes.io/os: windows
  tolerations:
    - key: "os"
      value: "windows"
      effect: NoSchedule
```

### 6. High-Performance Runners

Deploy runners with high CPU and memory for intensive workloads:

```yaml
# config/high-perf-runners.yaml
runnerSet:
  name: "high-perf-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "high-perf"
  replicas: 1
  image: "ghcr.io/actions/actions-runner:latest"
  resources:
    requests:
      cpu: 4000m
      memory: 8Gi
    limits:
      cpu: 16000m
      memory: 32Gi
  nodeSelector:
    node.kubernetes.io/instance-type: "Standard_E16s_v3"
```

## Custom Runner Images

### 7. Custom Runner with Development Tools

Build and deploy a custom runner image:

```bash
# Build custom runner image
./docker/build-custom-runner.sh -r myregistry.azurecr.io -t v1.0.0 -p

# Deploy with custom image
./scripts/deploy.sh deploy-custom -f config/custom-runners.yaml
```

### 8. Language-Specific Runners

Deploy runners optimized for specific programming languages:

```yaml
# config/python-runners.yaml
runnerSet:
  name: "python-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "python"
  replicas: 2
  image: "my-registry/python-runner:latest"
  env:
    - name: PYTHON_VERSION
      value: "3.11"
    - name: PIP_CACHE_DIR
      value: "/opt/pip-cache"
```

```yaml
# config/node-runners.yaml
runnerSet:
  name: "node-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "node"
  replicas: 2
  image: "my-registry/node-runner:latest"
  env:
    - name: NODE_VERSION
      value: "18"
    - name: NPM_CACHE
      value: "/opt/npm-cache"
```

## Auto-Scaling Examples

### 9. Cost-Optimized Auto-Scaling

Configure auto-scaling to minimize costs:

```yaml
# config/cost-optimized-runners.yaml
runnerSet:
  name: "cost-optimized-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "cost-optimized"
  replicas: 0  # Start with 0 runners
  autoscaling:
    enabled: true
    hpa:
      enabled: true
      minReplicas: 0
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
      scaleDownDelaySecondsAfterAdd: 300
      scaleDownUnneededTimeSeconds: 600
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
        policies:
          - type: Percent
            value: 50
            periodSeconds: 60
      scaleUp:
        stabilizationWindowSeconds: 0
        policies:
          - type: Percent
            value: 100
            periodSeconds: 15
```

### 10. Performance-Optimized Auto-Scaling

Configure auto-scaling for high-performance workloads:

```yaml
# config/performance-runners.yaml
runnerSet:
  name: "performance-runners"
  organization: "my-org"
  labels:
    - "self-hosted"
    - "linux"
    - "x64"
    - "performance"
  replicas: 2  # Keep some runners always available
  autoscaling:
    enabled: true
    hpa:
      enabled: true
      minReplicas: 2
      maxReplicas: 20
      targetCPUUtilizationPercentage: 80
      scaleDownDelaySecondsAfterAdd: 600
      scaleDownUnneededTimeSeconds: 900
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 600
        policies:
          - type: Percent
            value: 25
            periodSeconds: 120
      scaleUp:
        stabilizationWindowSeconds: 0
        policies:
          - type: Percent
            value: 100
            periodSeconds: 30
          - type: Pods
            value: 4
            periodSeconds: 30
        selectPolicy: Max
```

## Workflow Examples

### 11. Using Runners in GitHub Actions Workflows

Example workflows that use the deployed runners:

```yaml
# .github/workflows/standard-build.yml
name: Standard Build
on: [push, pull_request]
jobs:
  build:
    runs-on: [self-hosted, linux, x64, standard]
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          echo "Building on standard runner"
          # Your build steps here
```

```yaml
# .github/workflows/gpu-training.yml
name: GPU Training
on: [push]
jobs:
  train:
    runs-on: [self-hosted, linux, x64, gpu, ml]
    steps:
      - uses: actions/checkout@v3
      - name: Train Model
        run: |
          echo "Training on GPU runner"
          # Your ML training steps here
```

```yaml
# .github/workflows/python-tests.yml
name: Python Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: [self-hosted, linux, x64, python]
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          echo "Testing on Python runner"
          python -m pytest
```

## Monitoring and Maintenance

### 12. Check Runner Status

```bash
# Check all runners
./scripts/deploy.sh status

# Check specific runner deployment
kubectl get runnerdeployment -n github-runner-system
kubectl describe runnerdeployment standard-runners -n github-runner-system

# Check runner pods
kubectl get pods -n github-runner-system -l app.kubernetes.io/component=runner
```

### 13. Scale Runners Manually

```bash
# Scale up runners
kubectl scale runnerdeployment standard-runners --replicas=5 -n github-runner-system

# Scale down runners
kubectl scale runnerdeployment standard-runners --replicas=1 -n github-runner-system
```

### 14. Update Runner Configuration

```bash
# Update runner configuration
helm upgrade standard-runners ./charts/runner-set \
  -f config/values.yaml \
  -f config/standard-runners.yaml \
  --namespace github-runner-system
```

## Troubleshooting

### 15. Common Issues and Solutions

```bash
# Check controller logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=controller

# Check runner logs
kubectl logs -n github-runner-system -l app.kubernetes.io/component=runner

# Check events
kubectl get events -n github-runner-system --sort-by='.lastTimestamp'

# Check HPA status
kubectl get hpa -n github-runner-system
kubectl describe hpa standard-runners-hpa -n github-runner-system
```

These examples demonstrate various deployment patterns and configurations for different use cases. Adjust the configurations based on your specific requirements and infrastructure constraints. 