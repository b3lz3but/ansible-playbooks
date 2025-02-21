#!/bin/bash

# Script: Interactive Ansible Playbook Runner
# Description: Provides a GUI to select and run Ansible playbooks
# Author: System Administrator
# Last Modified: 2024

# Color definitions for visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check and install missing dependencies
check_dependencies() {
    local deps=(ansible sshpass dialog whiptail)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}Installing $dep...${NC}"
            apt-get update && apt-get install -y "$dep"
        fi
    done
}

# Function to get server IP and display access link
get_server_ip() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}🌐 Access Webmin Admin Panel at: https://$SERVER_IP:5761${NC}"
}

# Ensure inventory file exists
if [ ! -f "/ansible/inventory.ini" ]; then
    echo -e "${RED}❌ Error: inventory.ini not found! Please add an inventory file.${NC}"
    exit 1
fi

# Install dependencies if missing
check_dependencies

# Determine available menu command
if command -v whiptail &> /dev/null; then
    menu_cmd="whiptail"
elif command -v dialog &> /dev/null; then
    menu_cmd="dialog"
else
    echo "❌ No menu system found. Falling back to text input."
    menu_cmd="echo"
fi

# Define available playbooks
playbooks=(
    update_packages.yml
    restart_services.yml
    check_disk_space.yml
    system_health_monitor.yml
    security_scan.yml
    backup_files.yml
    user_management.yml
    log_cleanup.yml
    network_check.yml
    system_administration.yml
    networking.yml
    scripting_automation.yml
    monitoring_logging.yml
    security_hardening.yml
    troubleshooting.yml
    cloud_management.yml
    containerization.yml
    ci_cd.yml
    database_admin.yml
    documentation.yml
    collaboration.yml
)

# Generate menu options
menu_options=()
for playbook in "${playbooks[@]}"; do
    menu_options+=("$playbook" "Run $playbook" OFF)
done

# Display selection menu
CHOICE="$($menu_cmd --title 'Ansible Playbook Selection' --checklist \
    'Select playbooks to run (Space to select, Enter to confirm):' 25 78 15 \
    "${menu_options[@]}" 3>&1 1>&2 2>&3)"

# Check if any playbooks were selected
if [[ -z "$CHOICE" ]]; then
    echo "❌ No playbooks selected. Exiting."
    exit 1
fi

# Run selected playbooks
for playbook in $CHOICE; do
    ansible-playbook -i /ansible/inventory.ini "/ansible/playbooks/$playbook"
done

echo -e "${GREEN}✅ Playbooks executed successfully!${NC}"

# Print server IP for access
get_server_ip

# Keep container running
tail -f /dev/null
