# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables
ENV TERM=xterm
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=1
ENV PYTHONUNBUFFERED=1

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible sshpass dialog whiptail python3 python3-pip git ttyd \
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

# Expose ttyd for web-based terminal access
EXPOSE 7681

# Automatically start interactive_ansible.sh via ttyd (web-based terminal)
CMD ["ttyd", "-p", "7681", "bash", "/ansible/interactive_ansible.sh"]
