# =========================================
# === Build Stage: Compile & Install ===
# =========================================
FROM ubuntu:22.04 AS builder

# Set environment variables for build process
ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=17.1.0 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VENV_PATH=/opt/venv \
    AWX_PATH=/opt/awx

# Install essential build dependencies
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
    # Added for uwsgi compilation
    libpcre3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python3 -m venv $VENV_PATH && \
    . $VENV_PATH/bin/activate && \
    pip install --upgrade pip wheel setuptools

# Clone AWX repository (specific version)
RUN git clone -b ${AWX_VERSION} --depth 1 https://github.com/ansible/awx.git $AWX_PATH

RUN test -f "$AWX_PATH/requirements/requirements.txt" && (echo "ERROR: requirements.txt missing" && exit 1)
RUN test -f "$AWX_PATH/requirements/requirements.txt" || (echo "ERROR: requirements.txt missing" && exit 1)

# Ensure the AWX data directory exists and mark installation as complete
RUN mkdir -p /opt/awx/data && touch /opt/awx/data/.installed

# Install Python dependencies
RUN . $VENV_PATH/bin/activate && \
    pip install --no-cache-dir -r $AWX_PATH/requirements/requirements.txt && \
    rm -rf ~/.cache/pip

# Remove build dependencies to reduce final image size
RUN apt-get remove -y build-essential pkg-config make gcc libpcre3-dev && apt-get autoremove -y

# =========================================
# === Final Runtime Stage ===
# =========================================
FROM ubuntu:22.04

LABEL maintainer="Ciprian <ciprian@admintools.io>" \
    description="AWX (Ansible Tower) container" \
    version="24.6.0" \
    security="SECURITY_NIST_APPROVED=true"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=17.1.0 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:${PATH}" \
    AWX_USER=awx-user \
    AWX_GROUP=awx-group \
    VENV_PATH=/opt/venv \
    AWX_PATH=/opt/awx

# Install essential runtime dependencies
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
    xmlsec1 \
    libxmlsec1-openssl && \
    rm -rf /var/lib/apt/lists/*

# Install PyYAML and Ansible
RUN pip3 install --no-cache-dir pyyaml ansible
RUN pip install --no-cache-dir pyyaml ansible
# Create dedicated user & group
RUN groupadd -r ${AWX_GROUP} && \
    useradd -r -g ${AWX_GROUP} -d /home/${AWX_USER} -m -s /sbin/nologin ${AWX_USER}

# Copy built application from builder stage
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} $VENV_PATH $VENV_PATH
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} $AWX_PATH $AWX_PATH

# Set working directory
WORKDIR $AWX_PATH/installer

# Copy configuration files
COPY --chown=${AWX_USER}:${AWX_GROUP} inventory.ini /opt/awx/installer/inventory
COPY --chown=${AWX_USER}:${AWX_GROUP} entrypoint.sh /entrypoint.sh
COPY --chown=${AWX_USER}:${AWX_GROUP} utils.sh /opt/awx/utils.sh
COPY --chown=${AWX_USER}:${AWX_GROUP} logger.sh /opt/awx/logger.sh

# Ensure scripts have execution permissions
RUN chmod 0750 /entrypoint.sh

# Security hardening
RUN echo "fs.suid_dumpable=0" >> /etc/sysctl.conf && \
    echo "kernel.core_pattern=|/bin/false" >> /etc/sysctl.conf && \
    chmod 600 /etc/sysctl.conf

# Set file ownership at the end (after all copies)
RUN chown -R ${AWX_USER}:${AWX_GROUP} $AWX_PATH && chmod -R g-w,o-w $AWX_PATH

# Run as non-root user
USER ${AWX_USER}

# Expose necessary ports
EXPOSE 8052

# Healthcheck for AWX service
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=5 \
    CMD curl -fsSL http://localhost:8052/health || exit 1

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]