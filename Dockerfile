# Use specific Ubuntu version for stability
FROM ubuntu:22.04

# Add metadata
LABEL maintainer="DevOps Team"
LABEL description="Ansible control node container"

# Prevent apt from prompting for input and set timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install dependencies and create ansible user in a single layer to optimize image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    sshpass \
    dialog \
    whiptail \  
    python3 \
    python3-pip \
    git \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Create ansible user and required directories
    && useradd -m -s /bin/bash ansible \
    && mkdir -p /ansible /ansible/.ansible \
    && chown -R ansible:ansible /ansible

# Switch to non-root user for security
USER ansible
WORKDIR /ansible

# Set up ansible configuration directory
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV ANSIBLE_HOST_KEY_CHECKING=False

# Add healthcheck to verify ansible is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ansible --version || exit 1

# Default command
CMD ["ansible-playbook", "--version"]
