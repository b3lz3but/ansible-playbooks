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
    ansible \
    sshpass \
    dialog \
    whiptail \
    python3 \
    python3-pip \
    git \
    wget \
    perl \
    openssl \
    net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Webmin
RUN wget -q http://prdownloads.sourceforge.net/webadmin/webmin_2.013_all.deb && \
    dpkg --install webmin_2.013_all.deb || apt-get -fy install && \
    rm -f webmin_2.013_all.deb

# Expose Webmin port
EXPOSE 10000

# Copy Python requirements and install them
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Copy project files
COPY . /ansible
WORKDIR /ansible

# Ensure interactive script is executable
RUN chmod +x /ansible/interactive_ansible.sh

# Copy custom startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start Webmin & Run Ansible
ENTRYPOINT ["/entrypoint.sh"]
