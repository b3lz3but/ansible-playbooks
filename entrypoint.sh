#!/bin/bash
set -e

echo "🔄 Starting Webmin directly..."

# Start Webmin without using systemctl or service
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

# Inform the user of the externally accessible URL (mapped port 5761)
echo "🌍 Webmin is available at: https://$IP_ADDRESS:5761"

# Run the Ansible interactive script if it exists
if [ -f /ansible/interactive_ansible.sh ]; then
    echo "▶️ Starting Ansible interactive script..."
    /ansible/interactive_ansible.sh
else
    echo "⚠️ Warning: /ansible/interactive_ansible.sh not found"
fi

# Keep the container running by tailing the Webmin log
exec tail -f /var/log/webmin/miniserv.log
