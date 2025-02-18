#!/bin/bash

# Script: Interactive Ansible Playbook Runner
# Description: Interactive menu to select and run Ansible playbooks
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
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}Installing $dep...${NC}"
            apt update && apt install -y $dep
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
if [ ! -f "inventory.ini" ]; then
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
    echo "❌ Error: Menu system is unavailable. Falling back to text input."
    menu_cmd="echo"
fi

# Define playbook categories (Fixes missing variable)
declare -A playbook_categories=(
    ["System Management"]="update_packages.yml restart_services.yml check_disk_space.yml"
    ["Security"]="security_scan.yml user_management.yml"
    ["Maintenance"]="backup_files.yml log_cleanup.yml"
    ["Networking"]="network_check.yml"
    ["DevOps"]="containerization.yml ci_cd.yml"
)

# Step 3: Create menu options from categories
menu_options=()
for category in "${!playbook_categories[@]}"; do
    for playbook in ${playbook_categories[$category]}; do
        menu_options+=("$playbook" "$category" OFF)
    done
done

# Step 4: Debugging output for menu selection
echo -e "${GREEN}🔎 Running menu system: $menu_cmd${NC}"

# Short sleep to avoid race conditions in UI
sleep 1

# Display the checklist for user selection
if [ "$menu_cmd" = "whiptail" ]; then
    choices=$(whiptail --title "Ansible Playbook Selection" --checklist \
        "Select playbooks to run (Space to select, Enter to confirm):" 25 78 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)
elif [ "$menu_cmd" = "dialog" ]; then
    choices=$(dialog --clear --title "Ansible Playbook Selection" --checklist \
                "Select playbooks to run (Space to select, Enter to confirm):" \
                25 78 10 "${menu_options[@]}" 2>&1 >/dev/tty)
else
    # Fallback mechanism in case UI fails
    echo -e "${RED}⚠️ UI failed, falling back to text selection.${NC}"
    echo "Available Playbooks:"
    select playbook in "${!playbook_categories[@]}" exit; do
        if [[ "$playbook" == "exit" ]]; then
            echo "🚪 Exiting..."
            exit 0
        elif [[ -n "$playbook" ]]; then
            ansible-playbook -i inventory.ini "playbooks/$playbook"
        else
            echo "❌ Invalid selection, try again."
        fi
    done
fi

clear

# Step 5: Execute selected playbooks
if [ -n "$choices" ]; then
    echo -e "${BLUE}📜 Selected playbooks: $choices${NC}"
    for playbook in $choices; do
        if [ -f "playbooks/$playbook" ]; then
            echo -e "${GREEN}▶️ Running: $playbook${NC}"
            ansible-playbook -i inventory.ini "playbooks/$playbook"
        else
            echo -e "${RED}⚠️ Playbook $playbook not found!${NC}"
        fi
    done
    echo -e "${GREEN}✅ All selected playbooks have been executed successfully!${NC}"
else
    echo -e "${RED}❌ No playbooks selected. Exiting.${NC}"
    exit 1
fi
