#!/bin/bash

# Custom GitHub Actions Runner Entrypoint
# This script handles initialization and startup of the custom runner

set -e

# Function to print colored output
print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to verify installed tools
verify_tools() {
    print_info "Verifying installed tools..."
    
    local tools=(
        "git"
        "docker"
        "node"
        "npm"
        "python3"
        "pip3"
        "go"
        "cargo"
        "dotnet"
        "java"
        "mvn"
        "gradle"
    )
    
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            print_success "$tool is available"
        else
            print_warning "$tool is not available"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Missing tools: ${missing_tools[*]}"
    fi
}

# Function to set up environment
setup_environment() {
    print_info "Setting up environment..."
    
    # Set up Go environment
    if command_exists go; then
        export GOROOT="/usr/local/go"
        export GOPATH="/home/runner/go"
        export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"
    fi
    
    # Set up Rust environment
    if [ -f "/home/runner/.cargo/env" ]; then
        source "/home/runner/.cargo/env"
    fi
    
    # Set up Java environment
    if command_exists java; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    fi
    
    # Set up Node.js environment
    if command_exists npm; then
        export PATH="/home/runner/.npm-global/bin:$PATH"
    fi
    
    print_success "Environment setup completed"
}

# Function to verify Docker daemon
verify_docker() {
    if command_exists docker; then
        print_info "Verifying Docker daemon..."
        
        # Check if Docker daemon is running
        if docker info >/dev/null 2>&1; then
            print_success "Docker daemon is running"
        else
            print_warning "Docker daemon is not running"
        fi
    fi
}

# Function to verify cloud CLI tools
verify_cloud_tools() {
    print_info "Verifying cloud CLI tools..."
    
    local cloud_tools=(
        "aws"
        "az"
        "gcloud"
    )
    
    for tool in "${cloud_tools[@]}"; do
        if command_exists "$tool"; then
            print_success "$tool is available"
        else
            print_warning "$tool is not available"
        fi
    done
}

# Function to create custom directories
create_directories() {
    print_info "Creating custom directories..."
    
    local directories=(
        "/opt/custom-tools"
        "/home/runner/go"
        "/home/runner/.cache"
        "/home/runner/.config"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
}

# Function to set permissions
set_permissions() {
    print_info "Setting permissions..."
    
    # Ensure runner user owns their home directory
    chown -R runner:runner /home/runner
    
    # Set permissions for custom tools directory
    chown -R runner:runner /opt/custom-tools
    
    print_success "Permissions set"
}

# Function to run health checks
run_health_checks() {
    print_info "Running health checks..."
    
    # Check disk space
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        print_warning "Disk usage is high: ${disk_usage}%"
    else
        print_success "Disk usage is acceptable: ${disk_usage}%"
    fi
    
    # Check memory
    local mem_available=$(free -m | awk 'NR==2{printf "%.1f", $7*100/$2}')
    if (( $(echo "$mem_available < 10" | bc -l) )); then
        print_warning "Available memory is low: ${mem_available}%"
    else
        print_success "Available memory is acceptable: ${mem_available}%"
    fi
    
    # Check network connectivity
    if curl -s --connect-timeout 5 https://api.github.com >/dev/null; then
        print_success "Network connectivity to GitHub is working"
    else
        print_warning "Network connectivity to GitHub is not working"
    fi
}

# Main initialization function
initialize() {
    print_info "Initializing custom GitHub Actions runner..."
    
    # Run initialization steps
    verify_tools
    setup_environment
    verify_docker
    verify_cloud_tools
    create_directories
    set_permissions
    run_health_checks
    
    print_success "Custom runner initialization completed"
}

# Handle signals
trap 'print_info "Received signal, shutting down..."; exit 0' SIGTERM SIGINT

# Run initialization
initialize

# Execute the original command
print_info "Starting GitHub Actions runner..."
exec "$@" 