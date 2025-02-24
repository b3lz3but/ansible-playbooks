#!/bin/bash
set -e

print_status() {
    echo "📢 $1"
}

check_prereqs() {
    if ! command -v ansible-playbook >/dev/null; then
        print_status "❌ ERROR: Ansible not found. Please ensure it's installed."
        exit 1
    fi
}

# Ensure PostgreSQL is available before starting AWX
print_status "🔍 Checking PostgreSQL connectivity..."
until PGPASSWORD=$AWX_DB_PASSWORD psql -h "$AWX_DB_HOST" -U "$AWX_DB_USER" -d "$AWX_DB_NAME" -c '\q'; do
  print_status "⏳ Waiting for PostgreSQL to be available..."
  sleep 5
done

print_status "✅ PostgreSQL is available."

print_status "🚀 Starting AWX installation..."

# Check prerequisites
check_prereqs

# Move to AWX installer directory
cd /opt/awx/installer || {
    print_status "❌ ERROR: AWX installer directory not found!"
    exit 1
}

# Ensure install.yml playbook exists
if [ ! -f "install.yml" ]; then
    print_status "❌ ERROR: install.yml playbook is missing!"
    exit 1
fi

# Run AWX installation playbook with progress indicator
print_status "📢 Running installation playbook..."
ansible-playbook -i inventory install.yml || {
    print_status "❌ ERROR: AWX installation failed. Check logs for details."
    exit 1
}

# Wait for AWX services to start
print_status "⏳ Waiting for AWX services to start..."
for i in {1..30}; do
    if curl -s -f http://localhost:8052 >/dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 10
    if [ $i -eq 30 ]; then
        print_status "❌ ERROR: AWX failed to start within the timeout period."
        exit 1
    fi
done

# Get AWX server IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

print_status "✅ AWX installation completed successfully!"
print_status "🌍 AWX is available at: http://$IP_ADDRESS:8052"
print_status "👉 Default credentials: admin / password"
print_status "📝 Please change the default password after first login"

# Keep container running
exec tail -f /dev/null
