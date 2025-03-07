FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    ansible \
    sshpass \
    curl \
    jq \
    git \
    openssh-client \
    python3-yaml \
    sudo \
    whiptail \
    coreutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /ansible/playbooks /var/log/ansible

# Copy project files
COPY playbooks /ansible/playbooks
COPY inventory.ini /ansible/inventory.ini
COPY config.yaml /ansible/config.yaml
COPY logger.sh /ansible/logger.sh
COPY utils.sh /ansible/utils.sh
COPY Interactive_script.sh /ansible/Interactive_script.sh
COPY api.py /ansible/api.py

# Set permissions
RUN chmod +x /ansible/*.sh

WORKDIR /ansible

# Install Flask
RUN pip3 install flask

# Run Flask API and keep the container alive
CMD ["bash", "-c", "python3 /ansible/api.py & tail -f /dev/null"]
