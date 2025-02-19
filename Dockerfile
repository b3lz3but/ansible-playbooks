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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add repositories and update
RUN add-apt-repository universe && \
    apt-get update

# Install Ansible and other tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ansible \
    sshpass \
    dialog \
    whiptail \
    python3 \
    python3-pip \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Cockpit packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cockpit \
    cockpit-ws \
    cockpit-bridge \
    cockpit-system \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies and scripts
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY . /ansible
WORKDIR /ansible

# Make sure interactive script is executable
RUN chmod +x /ansible/interactive_ansible.sh

# Keep container running after launching services
CMD ["/bin/bash", "-c", "/usr/lib/cockpit-ws & sleep 5 && /ansible/interactive_ansible.sh; tail -f /dev/null"]
