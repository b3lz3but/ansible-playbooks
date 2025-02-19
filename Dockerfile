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
    libnet-ssleay-perl \
    libauthen-pam-perl \
    libio-pty-perl \
    apt-show-versions \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Webmin correctly
RUN wget -q http://prdownloads.sourceforge.net/webadmin/webmin_2.013_all.deb && \
    dpkg --install webmin_2.013_all.deb || apt-get -fy install && \
    rm -f webmin_2.013_all.deb

# Ensure Webmin is installed before setting permissions
RUN test -d /etc/webmin && chmod -R 755 /etc/webmin || echo "Webmin directory not found, skipping chmod"

# Copy dependencies and scripts
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY . /ansible
WORKDIR /ansible

# Make scripts executable
RUN chmod +x /ansible/interactive_ansible.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
