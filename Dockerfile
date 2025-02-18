# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Add metadata
LABEL maintainer="DevOps Team"
LABEL description="Ansible control node container"

# Prevent apt from prompting for input and set timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install dependencies
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
    && rm -rf /var/lib/apt/lists/*

# Create ansible user and ensure correct permissions
RUN useradd -m -s /bin/bash ansible
RUN mkdir -p /ansible /ansible/.ansible && chown -R ansible:ansible /ansible

# Copy the interactive script before switching users
COPY interactive_ansible.sh /ansible/interactive_ansible.sh
RUN chmod +x /ansible/interactive_ansible.sh && chown ansible:ansible /ansible/interactive_ansible.sh

# Switch to ansible user
USER ansible
WORKDIR /ansible

# Set Ansible environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV ANSIBLE_HOST_KEY_CHECKING=False

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ansible --version || exit 1

# Default command
ENTRYPOINT ["/bin/bash", "/ansible/interactive_ansible.sh"]
