# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables
ENV TERM=xterm
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=1
ENV PYTHONUNBUFFERED=1

# Install required packages, including Cockpit
RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible sshpass dialog whiptail python3 python3-pip git \
    cockpit cockpit-ws cockpit-bridge cockpit-system cockpit-networkmanager \
    && rm -rf /var/lib/apt/lists/*

# Create ansible user
RUN useradd -m -s /bin/bash ansible

# Ensure correct directory structure
RUN mkdir -p /ansible/playbooks && chown -R ansible:ansible /ansible

# Copy necessary files
COPY interactive_ansible.sh /ansible/interactive_ansible.sh
COPY inventory.ini /ansible/inventory.ini
COPY ansible.cfg /ansible/ansible.cfg

# Ensure script has execution permissions
RUN chmod +x /ansible/interactive_ansible.sh && chown ansible:ansible /ansible/interactive_ansible.sh

# Set working directory
WORKDIR /ansible

# Expose Cockpit Web UI port
EXPOSE 9090

# Start Cockpit directly (without systemctl) in the foreground
CMD ["/usr/lib/cockpit-ws"]
