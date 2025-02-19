#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Webmin service..."
service webmin start || { echo "❌ Failed to start Webmin"; exit 1; }

# Wait for Webmin to be ready
max_attempts=30
attempt=1
while ! curl -k -s https://localhost:10000 >/dev/null; do
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Webmin failed to start after $max_attempts attempts"
        exit 1
    fi
    echo "⏳ Waiting for Webmin to start (attempt $attempt/$max_attempts)..."
    sleep 1
    ((attempt++))
done

# Get the container's IP address dynamically
IP_ADDRESS=$(ip route get 1 | awk '{print $7;exit}')
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
fi

echo "🔗 Webmin is available at: https://$IP_ADDRESS:10000"

# Run Ansible interactive script if available
if [ -f /ansible/interactive_ansible.sh ]; then
    echo "▶️ Starting Ansible interactive script..."
    chmod +x /ansible/interactive_ansible.sh
    /ansible/interactive_ansible.sh
else
    echo "⚠️ Warning: /ansible/interactive_ansible.sh not found"
fi

# Handle SIGTERM gracefully
trap 'echo "🚨 Received SIGTERM, stopping services..."; service webmin stop; exit 0' SIGTERM

# Keep the container running
echo "✅ Container is running..."
exec tail -f /dev/null
