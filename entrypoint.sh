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
echo "👉 To run playbooks via Webmin, use the CGI script at: https://$IP_ADDRESS:5761/ansible_webmin.cgi"

# Keep the container running by tailing the Webmin log
exec tail -f /var/log/webmin/miniserv.log
