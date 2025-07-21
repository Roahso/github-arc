#!/bin/bash

# Build Custom GitHub Actions Runner Image
# This script builds and pushes the custom runner image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --registry       Docker registry (default: localhost:5000)"
    echo "  -t, --tag            Image tag (default: latest)"
    echo "  -p, --push           Push image to registry"
    echo "  -n, --no-cache       Build without cache"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -r myregistry.azurecr.io -t v1.0.0 -p"
    echo "  $0 --no-cache"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are satisfied."
}

# Function to build image
build_image() {
    local registry=$1
    local tag=$2
    local no_cache=$3
    
    local image_name="${registry}/custom-runner:${tag}"
    local build_context="$(dirname "$0")/custom-runner"
    
    print_info "Building custom runner image: $image_name"
    
    # Build arguments
    local build_args=""
    if [ "$no_cache" = true ]; then
        build_args="--no-cache"
    fi
    
    # Build the image
    docker build $build_args \
        --tag "$image_name" \
        --file "$build_context/Dockerfile" \
        "$build_context"
    
    print_success "Image built successfully: $image_name"
    
    # Return the image name for later use
    echo "$image_name"
}

# Function to push image
push_image() {
    local image_name=$1
    
    print_info "Pushing image to registry: $image_name"
    
    docker push "$image_name"
    
    print_success "Image pushed successfully: $image_name"
}

# Function to tag image
tag_image() {
    local source_image=$1
    local target_image=$2
    
    print_info "Tagging image: $source_image -> $target_image"
    
    docker tag "$source_image" "$target_image"
    
    print_success "Image tagged successfully"
}

# Function to clean up
cleanup() {
    local image_name=$1
    
    print_info "Cleaning up local image: $image_name"
    
    docker rmi "$image_name" 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Main script
main() {
    # Default values
    REGISTRY="localhost:5000"
    TAG="latest"
    PUSH=false
    NO_CACHE=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -p|--push)
                PUSH=true
                shift
                ;;
            -n|--no-cache)
                NO_CACHE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Build image
    IMAGE_NAME=$(build_image "$REGISTRY" "$TAG" "$NO_CACHE")
    
    # Push image if requested
    if [ "$PUSH" = true ]; then
        push_image "$IMAGE_NAME"
    fi
    
    # Show summary
    print_success "Build completed successfully!"
    print_info "Image: $IMAGE_NAME"
    if [ "$PUSH" = true ]; then
        print_info "Image has been pushed to registry"
    else
        print_info "Image is available locally"
        print_info "To push the image, run: docker push $IMAGE_NAME"
    fi
    
    # Show usage instructions
    echo ""
    print_info "To use this image in your runner configuration, update config/custom-runners.yaml:"
    echo "  runnerSet:"
    echo "    image: \"$IMAGE_NAME\""
}

# Run main function
main "$@" 