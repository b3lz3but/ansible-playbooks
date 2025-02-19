# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_FORCE_COLOR=1
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    cockpit \
    cockpit-ws \
    cockpit-bridge \
    cockpit-system \
    ansible \
    sshpass \
    dialog \
    whiptail \
    python3 \
    python3-pip \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Python requirements and install
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Copy project files
COPY . /ansible
WORKDIR /ansible

# Ensure script is executable
RUN chmod +x /ansible/interactive_ansible.sh

# Start Cockpit Web UI & run Ansible script automatically
CMD ["/bin/bash", "-c", "/usr/lib/cockpit-ws & sleep 5 && /ansible/interactive_ansible.sh"]
