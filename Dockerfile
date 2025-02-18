# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set non-interactive mode to prevent installation prompts
ENV DEBIAN_FRONTEND=noninteractive
# Ensure UI menus work inside Docker
ENV TERM=xterm

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

# Create ansible user and fix permissions
RUN useradd -m -s /bin/bash ansible
RUN mkdir -p /ansible /ansible/.ansible && chown -R ansible:ansible /ansible

# Copy interactive script with correct permissions
COPY interactive_ansible.sh /ansible/interactive_ansible.sh
RUN chmod +x /ansible/interactive_ansible.sh && chown ansible:ansible /ansible/interactive_ansible.sh

# Switch to ansible user
USER ansible
WORKDIR /ansible

# Ensure script executes on container start
ENTRYPOINT ["/bin/bash", "/ansible/interactive_ansible.sh"]
