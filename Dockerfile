FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=UTC
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=1
ENV PYTHONUNBUFFERED=1

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    ansible \
    sshpass \
    dialog \
    whiptail \
    python3 \
    python3-pip \
    git \
    wget \
    perl \
    libnet-ssleay-perl \
    libauthen-pam-perl \
    libio-pty-perl \
    apt-show-versions \
    python \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Webmin using the latest repository setup script
RUN curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh && \
    sh setup-repos.sh && \
    apt-get update && \
    apt-get install -y webmin && \
    rm -f setup-repos.sh

# Ensure Webmin has the correct permissions
RUN test -d /etc/webmin && chmod -R 755 /etc/webmin || echo "⚠️ Webmin directory not found, skipping chmod"

# Copy dependencies and scripts
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY . /ansible
WORKDIR /ansible

# Copy the entrypoint script to the root folder
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /ansible/interactive_ansible.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
