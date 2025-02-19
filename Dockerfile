# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_FORCE_COLOR=1

# Install basic dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add repositories and update
RUN add-apt-repository universe && \
    apt-get update

# Install Ansible, Cockpit, and other tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ansible \
    sshpass \
    dialog \
    whiptail \
    python3 \
    python3-pip \
    git \
    cockpit \
    cockpit-ws \
    cockpit-bridge \
    cockpit-system \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy dependencies and scripts
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY . /ansible
WORKDIR /ansible

# Make sure the script is executable
RUN chmod +x /ansible/interactive_ansible.sh

# Expose Cockpit web interface
EXPOSE 5761

# Start Cockpit and run Ansible automation on startup
CMD ["/bin/bash", "-c", "/usr/lib/cockpit-ws & sleep 5 && /ansible/interactive_ansible.sh && tail -f /dev/null"]
