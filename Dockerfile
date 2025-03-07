FROM ubuntu:22.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND="noninteractive"

# Install required packages
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /ansible/playbooks /var/log/ansible

# Copy project files into the container
COPY playbooks /ansible/playbooks
COPY inventory.ini /ansible/inventory.ini
COPY config.yaml /ansible/config.yaml
COPY logger.sh /ansible/logger.sh
COPY utils.sh /ansible/utils.sh
COPY Interactive_script.sh /ansible/Interactive_script.sh
# Install Flask in the same Dockerfile
RUN pip3 install flask

# Copy the API script
COPY api.py /ansible/api.py

# Expose Flask API port
EXPOSE 5000
# Set permissions
RUN chmod +x /ansible/*.sh

# Default work directory
WORKDIR /ansible

# Entrypoint and command to run both API and interactive script
ENTRYPOINT ["bash"]
CMD ["bash", "-c", "python3 /ansible/api.py & ./Interactive_script.sh"]
CMD ["Interactive_script.sh"]
