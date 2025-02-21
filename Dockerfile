# Build stage
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=23.1.0 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install security updates and build dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    git=1:2.34.* \
    python3=3.10.* \
    python3-pip=22.0.* \
    python3-venv \
    && python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && git clone -b ${AWX_VERSION} --depth 1 https://github.com/ansible/awx.git /opt/awx \
    && pip install --upgrade pip wheel setuptools \
    && pip install -r /opt/awx/requirements.txt

# COPY the requirements.txt before installing dependencies
COPY requirments.txt /opt/awx/requirements.txt

# Final stage
FROM ubuntu:22.04

LABEL maintainer="Ciprian <ciprian@admintools.io>" \
    description="AWX (Ansible Tower) container" \
    version="23.1.0" \
    security="SECURITY_NIST_APPROVED=true"

ENV DEBIAN_FRONTEND=noninteractive \
    AWX_VERSION=23.1.0 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:${PATH}" \
    AWX_USER=awx-user \
    AWX_GROUP=awx-user

# Install runtime dependencies and security updates
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    docker.io=20.10.* \
    ansible=2.10.* \
    curl=7.81.* \
    ca-certificates \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r ${AWX_GROUP} \
    && useradd -r -g ${AWX_GROUP} -d /home/${AWX_USER} -m -s /sbin/nologin ${AWX_USER}

# Copy virtual environment from builder
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} /opt/venv /opt/venv
COPY --from=builder --chown=${AWX_USER}:${AWX_GROUP} /opt/awx /opt/awx

WORKDIR /opt/awx/installer

COPY --chown=${AWX_USER}:${AWX_GROUP} inventory.ini /opt/awx/installer/inventory
COPY --chown=${AWX_USER}:${AWX_GROUP} entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chown -R ${AWX_USER}:${AWX_GROUP} /opt/awx \
    && chmod -R g-w,o-w /opt/awx

# Add security configurations
RUN echo "fs.suid_dumpable=0" >> /etc/sysctl.conf \
    && echo "kernel.core_pattern=|/bin/false" >> /etc/sysctl.conf \
    && chmod 600 /etc/sysctl.conf

USER ${AWX_USER}

EXPOSE 8052

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8052/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
