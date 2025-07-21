# Custom GitHub Actions Runner Image
# Based on the official Microsoft actions-runner image with additional tools

FROM ghcr.io/actions/actions-runner:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_USER=runner

# Install additional system packages
RUN apt-get update && apt-get install -y \
    # Development tools
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    # Version control
    git-lfs \
    # Cloud tools
    awscli \
    azure-cli \
    gcloud \
    # Container tools
    docker.io \
    docker-compose \
    # Network tools
    curl \
    wget \
    jq \
    # Monitoring tools
    htop \
    iotop \
    # Additional utilities
    unzip \
    zip \
    tree \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz \
    && rm go1.21.0.linux-amd64.tar.gz

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install .NET SDK
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-7.0 \
    && rm -rf /var/lib/apt/lists/*

# Install Java
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    maven \
    gradle \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python packages
RUN pip3 install --no-cache-dir \
    pytest \
    pytest-cov \
    black \
    flake8 \
    mypy \
    requests \
    boto3 \
    azure-storage-blob \
    google-cloud-storage

# Install additional Node.js packages
RUN npm install -g \
    typescript \
    eslint \
    prettier \
    jest \
    yarn

# Set up environment variables
ENV PATH="/usr/local/go/bin:/home/runner/.cargo/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV GOROOT="/usr/local/go"
ENV GOPATH="/home/runner/go"

# Create directories for custom tools
RUN mkdir -p /opt/custom-tools /home/runner/go

# Set ownership
RUN chown -R runner:runner /opt/custom-tools /home/runner/go

# Switch to runner user
USER runner

# Install user-level tools
RUN npm config set prefix '/home/runner/.npm-global' \
    && echo 'export PATH=/home/runner/.npm-global/bin:$PATH' >> /home/runner/.bashrc

# Install additional user tools
RUN pip3 install --user --no-cache-dir \
    pipenv \
    poetry

# Switch back to root for final setup
USER root

# Create symlinks for common tools
RUN ln -sf /usr/bin/python3 /usr/local/bin/python \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip

# Set up entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/start.sh"] 