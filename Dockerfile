# Dockerfile
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=UTC
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies, including iproute2 for the `ip` command
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    ansible \
    sshpass \
    dialog \
    whiptail \
    iproute2 \
    python3 \
    python3-pip \
    git \
    wget \
    perl \
    libnet-ssleay-perl \
    libauthen-pam-perl \
    libio-pty-perl \
    apt-show-versions \
    python-is-python3 \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Webmin from the official repository
RUN curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh && \
    echo "y" | sh setup-repos.sh && \
    apt-get update && \
    apt-get install -y webmin && \
    rm -f setup-repos.sh

# Ensure Webmin permissions are correct
RUN chmod -R 755 /etc/webmin || echo "⚠️ Webmin directory not found, skipping chmod"

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Copy project files and set working directory
COPY . /ansible
WORKDIR /ansible

# Copy and set permissions for the entrypoint script and interactive script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chmod +x /ansible/interactive_ansible.sh

# Expose Webmin port
EXPOSE 10000

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
