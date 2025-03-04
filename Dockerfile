# === Build Stage: Compile & Install ===
FROM ubuntu:22.04 AS builder

# Build environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=17.1.0 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VENV_PATH=/opt/venv \
    AWX_PATH=/opt/awx

# Install build dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libpython3-dev \
    zlib1g-dev \
    make \
    gcc \
    pkg-config \
    libxmlsec1-dev \
    xmlsec1 \
    libxmlsec1-openssl \
    libpcre3-dev \ 
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python3 -m venv $VENV_PATH && . $VENV_PATH/bin/activate && \
    pip install --upgrade pip wheel setuptools

# Clone AWX source (version 17.1.0)
RUN git clone -b ${AWX_VERSION} --depth 1 https://github.com/ansible/awx.git $AWX_PATH

# Ensure the AWX data directory exists (for installer marker)
RUN mkdir -p /opt/awx/data

# Copy requirements file into AWX source
COPY requirements.txt $AWX_PATH/requirements/requirements.txt

# Install Python dependencies inside the virtualenv
RUN . $VENV_PATH/bin/activate && \
    pip install --no-cache-dir -r $AWX_PATH/requirements/requirements.txt && \
    rm -rf ~/.cache/pip

# === Final Runtime Stage ===
FROM ubuntu:22.04

LABEL maintainer="Ciprian <ciprian@example.com>" \
    description="AWX (Ansible Tower) container" \
    version="24.6.0" \
    security="SECURITY_NIST_APPROVED=true"

# Set runtime environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=17.1.0 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:$PATH" \
    AWX_USER=awx-user \
    AWX_GROUP=awx-group \
    VENV_PATH=/opt/venv \
    AWX_PATH=/opt/awx

# Install runtime dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    python3-venv \
    sshpass \
    dialog \
    whiptail \
    curl \
    python3-yaml \
    jq \
    postgresql-client \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libpython3-dev \
    zlib1g-dev \
    libxmlsec1-dev \
    xmlsec1-openssl && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir pyyaml ansible

# Create non-root AWX user
RUN groupadd -r ${AWX_GROUP} && \
    useradd -r -g ${AWX_GROUP} -d /home/${AWX_USER} -m -s /sbin/nologin ${AWX_USER}

# Copy built application from builder stage
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} $VENV_PATH $VENV_PATH
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} $AWX_PATH $AWX_PATH

# Set working directory to installer
WORKDIR $AWX_PATH/installer

# Copy configuration and utility files
COPY --chown=${AWX_USER}:${AWX_GROUP} inventory.ini /opt/awx/installer/inventory
COPY --chown=${AWX_USER}:${AWX_GROUP} entrypoint.sh /entrypoint.sh
COPY --chown=${AWX_USER}:${AWX_GROUP} utils.sh /opt/awx/utils.sh
COPY --chown=${AWX_USER}:${AWX_GROUP} logger.sh /opt/awx/logger.sh

# Ensure entrypoint script is executable
RUN chmod 0750 /entrypoint.sh

# Security hardening
RUN echo "fs.suid_dumpable=0" >> /etc/sysctl.conf && \
    echo "kernel.core_pattern=|/bin/false" >> /etc/sysctl.conf && \
    chmod 600 /etc/sysctl.conf

# Adjust ownership and permissions
RUN chown -R ${AWX_USER}:${AWX_GROUP} $AWX_PATH && chmod -R g-w,o-w $AWX_PATH

# Switch to non-root user
USER ${AWX_USER}

# Expose AWX port
EXPOSE 8052

# Healthcheck for the AWX web service
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=5 \
    CMD curl -fsSL http://localhost:8052/health || exit 1

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
