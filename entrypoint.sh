#!/bin/bash
set -e

# Set default Webmin credentials (override via environment variables if needed)
WEBMIN_USER=${WEBMIN_USER:-root}
WEBMIN_PASS=${WEBMIN_PASS:-changeme}

echo "🔄 Setting Webmin credentials for user '${WEBMIN_USER}'..."
/usr/share/webmin/changepass.pl /etc/webmin ${WEBMIN_USER} ${WEBMIN_PASS}

echo "🔄 Starting Webmin directly..."
/usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf &

# Wait for Webmin to be ready
max_attempts=30
attempt=1
while ! curl -k -s https://localhost:10000 >/dev/null; do
    if [ "$attempt" -gt "$max_attempts" ]; then
        echo "⏳ Webmin failed to start after $max_attempts attempts!"
        exit 1
    fi
    echo "⏳ Waiting for Webmin to start (attempt $attempt/$max_attempts)..."
    sleep 1
    ((attempt++))
done

# Get the container's IP address
IP_ADDRESS=$(ip route get 1 | awk '{print $7; exit}')
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
fi

echo "🌍 Webmin is available at: https://$IP_ADDRESS:5761"
echo "👉 To run playbooks, go to the 'Ansible Playbook Runner' module in the Webmin interface."

# Check if Webmin log file exists and tail it, otherwise tail /dev/null
if [ -f /var/log/webmin/miniserv.log ]; then
    exec tail -f /var/log/webmin/miniserv.log
else
    echo "Log file not found. Tailing /dev/null instead."
    exec tail -f /dev/null
fi
