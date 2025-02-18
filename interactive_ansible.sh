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

# Step 3: Create menu options from categories
menu_options=()
for category in "${!playbook_categories[@]}"; do
    while read -r playbook comment; do
        if [ ! -z "$playbook" ]; then
            playbook=$(echo $playbook | xargs) # Trim whitespace
            menu_options+=("$playbook" "$category: $comment" OFF)
        fi
    done <<< "${playbook_categories[$category]}"
done

# Step 4: Debugging output for menu selection
echo -e "${GREEN}🔎 Running menu system: $menu_cmd${NC}"

# Display the checklist for user selection
if [ "$menu_cmd" = "whiptail" ]; then
    choices=$(whiptail --title "Ansible Playbook Selection" --checklist \
        "Select playbooks to run (Space to select, Enter to confirm):" 25 78 20 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)
elif [ "$menu_cmd" = "dialog" ]; then
    choices=$(dialog --clear --title "Ansible Playbook Selection" --checklist \
                "Select playbooks to run (Space to select, Enter to confirm):" \
                25 78 20 "${menu_options[@]}" 2>&1 >/dev/tty)
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
    if run_playbooks $choices; then
        echo -e "${GREEN}✅ All selected playbooks have been executed successfully!${NC}"
    else
        echo -e "${RED}❌ Some playbooks failed to execute properly.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ No playbooks selected. Exiting.${NC}"
    exit 1
fi
