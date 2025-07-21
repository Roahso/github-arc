#!/bin/bash

# GitHub Actions Runner Controller Deployment Script
# This script deploys the controller and runner scale sets to AKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command_exists helm; then
        print_error "Helm is not installed. Please install Helm 3.x first."
        exit 1
    fi
    
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    print_success "All prerequisites are satisfied."
}

# Function to check if namespace exists
namespace_exists() {
    kubectl get namespace "$1" >/dev/null 2>&1
}

# Function to create namespace
create_namespace() {
    local namespace=$1
    if ! namespace_exists "$namespace"; then
        print_status "Creating namespace: $namespace"
        kubectl create namespace "$namespace"
        print_success "Namespace $namespace created."
    else
        print_warning "Namespace $namespace already exists."
    fi
}

# Function to deploy controller
deploy_controller() {
    local namespace=$1
    local values_file=$2
    
    print_status "Deploying GitHub Actions Runner Controller..."
    
    if [ ! -f "$values_file" ]; then
        print_error "Values file not found: $values_file"
        print_error "Please copy config/values.yaml.example to config/values.yaml and update it with your configuration."
        exit 1
    fi
    
    helm upgrade --install github-runner-controller ./charts/controller \
        -f "$values_file" \
        --namespace "$namespace" \
        --create-namespace \
        --wait \
        --timeout 10m
    
    print_success "GitHub Actions Runner Controller deployed successfully."
}

# Function to deploy runner set
deploy_runner_set() {
    local namespace=$1
    local values_file=$2
    local runner_config=$3
    local release_name=$4
    
    print_status "Deploying runner set: $release_name"
    
    if [ ! -f "$values_file" ]; then
        print_error "Values file not found: $values_file"
        exit 1
    fi
    
    if [ ! -f "$runner_config" ]; then
        print_error "Runner configuration file not found: $runner_config"
        exit 1
    fi
    
    helm upgrade --install "$release_name" ./charts/runner-set \
        -f "$values_file" \
        -f "$runner_config" \
        --namespace "$namespace" \
        --wait \
        --timeout 10m
    
    print_success "Runner set $release_name deployed successfully."
}

# Function to check deployment status
check_deployment_status() {
    local namespace=$1
    
    print_status "Checking deployment status..."
    
    # Check controller deployment
    kubectl get pods -n "$namespace" -l app.kubernetes.io/component=controller
    
    # Check runner deployments
    kubectl get runnerdeployments -n "$namespace"
    
    # Check runners
    kubectl get runners -n "$namespace"
    
    print_success "Deployment status check completed."
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  deploy-controller    Deploy the GitHub Actions Runner Controller"
    echo "  deploy-standard      Deploy standard runners"
    echo "  deploy-custom        Deploy custom runners"
    echo "  deploy-all           Deploy controller and all runner sets"
    echo "  status               Check deployment status"
    echo "  uninstall            Uninstall all components"
    echo ""
    echo "Options:"
    echo "  -n, --namespace      Kubernetes namespace (default: github-runner-system)"
    echo "  -f, --values         Path to values file (default: config/values.yaml)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy-all"
    echo "  $0 deploy-controller -n my-namespace"
    echo "  $0 deploy-standard -f my-values.yaml"
}

# Main script
main() {
    # Default values
    NAMESPACE="github-runner-system"
    VALUES_FILE="config/values.yaml"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -f|--values)
                VALUES_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done
    
    # Check if command is provided
    if [ -z "$COMMAND" ]; then
        print_error "No command specified."
        show_usage
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Execute command
    case $COMMAND in
        deploy-controller)
            create_namespace "$NAMESPACE"
            deploy_controller "$NAMESPACE" "$VALUES_FILE"
            ;;
        deploy-standard)
            deploy_runner_set "$NAMESPACE" "$VALUES_FILE" "config/standard-runners.yaml" "standard-runners"
            ;;
        deploy-custom)
            deploy_runner_set "$NAMESPACE" "$VALUES_FILE" "config/custom-runners.yaml" "custom-runners"
            ;;
        deploy-all)
            create_namespace "$NAMESPACE"
            deploy_controller "$NAMESPACE" "$VALUES_FILE"
            deploy_runner_set "$NAMESPACE" "$VALUES_FILE" "config/standard-runners.yaml" "standard-runners"
            deploy_runner_set "$NAMESPACE" "$VALUES_FILE" "config/custom-runners.yaml" "custom-runners"
            ;;
        status)
            check_deployment_status "$NAMESPACE"
            ;;
        uninstall)
            print_status "Uninstalling all components..."
            helm uninstall custom-runners -n "$NAMESPACE" || true
            helm uninstall standard-runners -n "$NAMESPACE" || true
            helm uninstall github-runner-controller -n "$NAMESPACE" || true
            kubectl delete namespace "$NAMESPACE" || true
            print_success "All components uninstalled."
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 