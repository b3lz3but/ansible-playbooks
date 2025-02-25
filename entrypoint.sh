#!/usr/bin/env bash

# Exit immediately if any command fails
set -e
# Enable debug mode (prints each command before execution)
set -x

# Function to print status messages
print_status() {
    echo -e "\n📢 $1"
}

# Ensure required environment variables are set
: "${AWX_DB_HOST:?❌ ERROR: AWX_DB_HOST is not set!}"
: "${AWX_DB_USER:?❌ ERROR: AWX_DB_USER is not set!}"
: "${AWX_DB_PASSWORD:?❌ ERROR: AWX_DB_PASSWORD is not set!}"
: "${AWX_DB_NAME:?❌ ERROR: AWX_DB_NAME is not set!}"

# Ensure PostgreSQL is available before starting AWX
print_status "🔍 Checking PostgreSQL connectivity..."
MAX_RETRIES=30
WAIT_SECONDS=5
COUNTER=0

while ! PGPASSWORD="${AWX_DB_PASSWORD}" psql -h "${AWX_DB_HOST}" -U "${AWX_DB_USER}" -d "${AWX_DB_NAME}" -c "SELECT 1;" >/dev/null 2>&1; do
    print_status "⏳ Waiting for PostgreSQL to be available... (Attempt: $((COUNTER+1))/$MAX_RETRIES)"
    sleep $WAIT_SECONDS
    COUNTER=$((COUNTER+1))
    
    if [[ "$COUNTER" -ge "$MAX_RETRIES" ]]; then
        print_status "❌ ERROR: PostgreSQL is not available after $MAX_RETRIES attempts. Exiting..."
        psql -h "${AWX_DB_HOST}" -U "${AWX_DB_USER}" -d "${AWX_DB_NAME}" -c "SELECT 1;" || true
        exit 1
    fi
done

print_status "✅ PostgreSQL is available."

# Ensure Ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
    print_status "❌ ERROR: Ansible is not installed! Please ensure it's included in the container."
    exit 1
fi

# Move to AWX installer directory
if [ ! -d "/opt/awx/installer" ]; then
    print_status "❌ ERROR: AWX installer directory not found!"
    exit 1
fi
cd /opt/awx/installer

# Ensure `install.yml` playbook exists
if [ ! -f "install.yml" ]; then
    print_status "❌ ERROR: install.yml playbook is missing!"
    exit 1
fi

print_status "🚀 Starting AWX installation using Ansible..."

# Run the AWX installation playbook
if ! ansible-playbook -i inventory install.yml; then
    print_status "❌ ERROR: AWX installation failed! Check logs for details."
    exit 1
fi

# Wait for AWX services to become available
print_status "⏳ Waiting for AWX services to start..."
AWX_URL="http://localhost:8052/health"
AWX_MAX_WAIT=300  # 5 minutes
AWX_COUNTER=0
AWX_SLEEP=10

while ! curl -fsSL "$AWX_URL" >/dev/null; do
    print_status "⌛ Still waiting for AWX to become available... (Elapsed: $AWX_COUNTER seconds)"
    sleep "$AWX_SLEEP"
    AWX_COUNTER=$((AWX_COUNTER + AWX_SLEEP))

    if [[ "$AWX_COUNTER" -ge "$AWX_MAX_WAIT" ]]; then
        print_status "❌ ERROR: AWX did not start within the timeout period."
        exit 1
    fi
done

# Get server IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

print_status "✅ AWX installation completed successfully!"
print_status "🌍 AWX is available at: http://$IP_ADDRESS:8052"
print_status "👉 Default credentials: admin / password"
print_status "📝 Please change the default password after first login"

# Keep the container running properly
exec tail -f /dev/null
