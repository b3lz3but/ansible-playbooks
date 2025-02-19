#!/bin/bash

# Script: Interactive Ansible Playbook Runner
# Description: Interactive menu to select and run Ansible playbooks with a GUI
# Author: System Administrator
# Last Modified: 2024

# Color definitions for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check dependencies and install missing ones
check_dependencies() {
    local deps=(ansible sshpass dialog whiptail)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}Installing $dep...${NC}"
            apt-get update && apt-get install -y "$dep"
        fi
    done
}

# Function to display header
show_header() {
    echo -e "${BLUE}🚀 Welcome to the Ansible Automation Setup!${NC}"
    echo "========================================"
    echo "Select playbooks to run from the following categories:"
    echo ""
}

# Debugging check for TERM variable
echo -e "${GREEN}🔎 TERM value: $TERM${NC}"

# Ensure `inventory.ini` exists
if [ ! -f "/ansible/inventory.ini" ]; then
    echo -e "${RED}❌ Error: inventory.ini not found! Please add an inventory file.${NC}"
    exit 1
fi

# Ensure required dependencies are installed
check_dependencies

# Verify that whiptail or dialog is available
if ! command -v whiptail &> /dev/null && ! command -v dialog &> /dev/null; then
    echo "❌ Error: Neither whiptail nor dialog is installed."
    apt-get update && apt-get install -y whiptail dialog
fi

# Set default menu system
if command -v whiptail &> /dev/null; then
    menu_cmd="whiptail"
elif command -v dialog &> /dev/null; then
    menu_cmd="dialog"
else
    echo "❌ Error: Neither whiptail nor dialog is available. Falling back to text input."
    menu_cmd="echo"
fi

# Define playbook list
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

# Generate whiptail options
menu_options=()
for playbook in "${playbooks[@]}"; do
    menu_options+=("$playbook" "Run $playbook" OFF)
done

# Display selection menu
CHOICE="$($menu_cmd --title "Ansible Playbook Selection" --checklist \
    "Select playbooks to run (Space to select, Enter to confirm):" 25 78 15 \
    "${menu_options[@]}" 3>&1 1>&2 2>&3)

# Debugging output
if [[ -z "$CHOICE" ]]; then
    echo "❌ No playbooks selected. Exiting."
    exit 1
fi

# Run selected playbooks
echo "▶️ Running selected playbooks: $CHOICE"
for playbook in "$CHOICE"; do
    playbook_cleaned=$(echo "$playbook" | tr -d '"')  # Remove any extra quotes
    playbook_path="/ansible/playbooks/$playbook_cleaned"

    if [[ -f "$playbook_path" ]]; then
        echo -e "${BLUE}▶️ Running: $playbook_cleaned${NC}"
        if ansible-playbook -i /ansible/inventory.ini "$playbook_path" | tee -a /ansible/ansible.log; then
            echo -e "${GREEN}✅ Playbook $playbook_cleaned executed successfully!${NC}"
        else
            echo -e "${RED}❌ Error executing playbook $playbook_cleaned!${NC}"
        fi
    else
        echo -e "${RED}⚠️ Playbook $playbook_cleaned not found!${NC}"
    fi
done

echo -e "${GREEN}✅ Playbooks executed successfully!${NC}"
