# Image Sources

This document explains the Docker images used in this GitHub Actions Runner Controller deployment.

## Official Microsoft-Supported Images

This repository uses the **official Microsoft-supported GitHub Actions Runner Controller** from the [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller) repository, not the community-maintained version.

## Controller Images

### GitHub Actions Runner Controller
- **Image**: `ghcr.io/actions/actions-runner-controller:v0.1.0`
- **Source**: [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller)
- **Registry**: GitHub Container Registry (ghcr.io)
- **Maintainer**: Microsoft GitHub Actions Team

This image contains:
- The controller manager that manages runner deployments
- Webhook server for admission control
- Metrics server for monitoring

## Runner Images

### Standard Runners
- **Image**: `ghcr.io/actions/actions-runner:latest`
- **Source**: [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller)
- **Registry**: GitHub Container Registry (ghcr.io)
- **Maintainer**: Microsoft GitHub Actions Team

This image contains:
- GitHub Actions runner agent
- Basic Linux environment
- Standard development tools

### Custom Runners
- **Base Image**: `ghcr.io/actions/actions-runner:latest`
- **Custom Image**: Built locally or in your registry
- **Additional Tools**: Development tools, cloud CLIs, language runtimes

## Image Registry Information

### GitHub Container Registry (ghcr.io)
- **URL**: https://ghcr.io
- **Authentication**: Uses GitHub Personal Access Token or GitHub App
- **Rate Limits**: Higher limits for authenticated users

### Accessing Images
```bash
# Pull controller image
docker pull ghcr.io/actions/actions-runner-controller:v0.1.0

# Pull runner image
docker pull ghcr.io/actions/actions-runner:latest

# List available tags
docker run --rm ghcr.io/actions/actions-runner-controller:v0.1.0 --help
```

## Image Versions

### Current Versions
- **Controller**: `v0.1.0` (latest stable)
- **Runner**: `latest` (latest stable)

### Version Policy
- Controller versions follow semantic versioning
- Runner images use `latest` tag for automatic updates
- Custom images should be versioned appropriately

## Building Custom Images

### Base Image
```dockerfile
# Use official Microsoft runner as base
FROM ghcr.io/actions/actions-runner:latest

# Add your customizations
RUN apt-get update && apt-get install -y \
    your-custom-packages
```

### Building and Pushing
```bash
# Build custom image
./docker/build-custom-runner.sh -r your-registry.azurecr.io -t v1.0.0

# Push to registry
./docker/build-custom-runner.sh -r your-registry.azurecr.io -t v1.0.0 -p
```

## Security Considerations

### Image Security
- Official Microsoft images are regularly updated with security patches
- Images are scanned for vulnerabilities
- Base images use minimal attack surface

### Registry Security
- Use private registries for custom images
- Implement image scanning in CI/CD
- Use specific image tags instead of `latest` in production

### Authentication
```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Login to Azure Container Registry
az acr login --name your-registry
```

## Troubleshooting

### Image Pull Issues
```bash
# Check image availability
docker pull ghcr.io/actions/actions-runner-controller:v0.1.0

# Check authentication
docker login ghcr.io

# Check network connectivity
curl -I https://ghcr.io/v2/
```

### Version Compatibility
- Ensure controller and runner versions are compatible
- Check the [official documentation](https://github.com/actions/actions-runner-controller) for version matrix
- Test custom images before deploying to production

## Migration from Community Images

If migrating from the community-maintained images:

### Before (Community)
```yaml
controller:
  image:
    repository: actions/actions-runner-controller
    tag: "v0.28.0"

runnerSet:
  image: "ghcr.io/actions/actions-runner:latest"
```

### After (Official Microsoft)
```yaml
controller:
  image:
    repository: ghcr.io/actions/actions-runner-controller
    tag: "v0.1.0"

runnerSet:
  image: "ghcr.io/actions/actions-runner:latest"
```

### Migration Steps
1. Update image references in configuration files
2. Test deployment in non-production environment
3. Verify runner functionality
4. Deploy to production
5. Monitor for any issues

## Support

For issues with the official images:
- [GitHub Issues](https://github.com/actions/actions-runner-controller/issues)
- [GitHub Discussions](https://github.com/actions/actions-runner-controller/discussions)
- [Official Documentation](https://github.com/actions/actions-runner-controller) 