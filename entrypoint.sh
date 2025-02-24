#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status
set -x  # Debugging - print each command before executing

# Function to print status messages
print_status() {
    echo -e "\n📢 $1"
}

# Ensure PostgreSQL is available before starting AWX
print_status "🔍 Checking PostgreSQL connectivity..."
for i in {1..30}; do
    if PGPASSWORD="${AWX_DB_PASSWORD}" psql -h "${AWX_DB_HOST}" -U "${AWX_DB_USER}" -d "${AWX_DB_NAME}" -c '\q' >/dev/null 2>&1; then
        print_status "✅ PostgreSQL is available."
        break
    fi
    print_status "⏳ Waiting for PostgreSQL to be available..."
    sleep 5
    if [ $i -eq 30 ]; then
        print_status "❌ ERROR: PostgreSQL failed to become available!"
        exit 1
    fi
done

# Check if Ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
    print_status "❌ ERROR: Ansible not found! Ensure it's installed inside the container."
    exit 1
fi

# Move to the AWX installer directory
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
ansible-playbook -i inventory install.yml || {
    print_status "❌ ERROR: AWX installation failed! Check logs for details."
    exit 1
}

# Wait for AWX services to become available
print_status "⏳ Waiting for AWX services to start..."
for i in {1..30}; do
    if curl -fsSL http://localhost:8052/health >/dev/null 2>&1; then
        break
    fi
    print_status "⌛ Still waiting for AWX to become available..."
    sleep 10
    if [ $i -eq 30 ]; then
        print_status "❌ ERROR: AWX failed to start within the timeout period."
        exit 1
    fi
done

# Get server IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

print_status "✅ AWX installation completed successfully!"
print_status "🌍 AWX is available at: http://$IP_ADDRESS:8052"
print_status "👉 Default credentials: admin / password"
print_status "📝 Please change the default password after first login"

# Keep the container running with a proper process
exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
