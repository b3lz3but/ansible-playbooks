FROM ubuntu:22.04

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
    && rm -rf /var/lib/apt/lists/* \
    && test -f /usr/lib/cockpit/cockpit-ws

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY . /ansible
WORKDIR /ansible

ENTRYPOINT ["ansible-playbook"]