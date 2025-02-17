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

# Function to check dependencies
check_dependencies() {
    local deps=(ansible sshpass dialog)
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

# Function to run selected playbooks with error handling
run_playbooks() {
    local exit_status=0
    for playbook in "$@"; do
        echo -e "${BLUE}Running: $playbook${NC}"
        if [ -f "playbooks/$playbook" ]; then
            ansible-playbook -i inventory.ini "playbooks/$playbook"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error running $playbook${NC}"
                exit_status=1
            fi
        else
            echo -e "${RED}Playbook $playbook not found${NC}"
            exit_status=1
        fi
    done
    return $exit_status
}

# Organized playbook categories
declare -A playbook_categories=(
    # System Management
    ["System Management"]="
        update_packages.yml         # System package updates
        restart_services.yml        # Service management
        check_disk_space.yml       # Disk space monitoring
        system_health_monitor.yml   # System health checks
        system_administration.yml   # General admin tasks
    "
    
    # Security
    ["Security"]="
        security_scan.yml          # Security vulnerability scanning
        security_hardening.yml     # System hardening procedures
        user_management.yml        # User access control
    "
    
    # Maintenance
    ["Maintenance"]="
        backup_files.yml           # System backup procedures
        log_cleanup.yml            # Log rotation and cleanup
        troubleshooting.yml        # System troubleshooting
    "
    
    # Network
    ["Network"]="
        network_check.yml          # Network connectivity tests
        networking.yml             # Network configuration
    "
    
    # DevOps
    ["DevOps"]="
        scripting_automation.yml   # Automation scripts
        monitoring_logging.yml     # Monitoring setup
        ci_cd.yml                 # CI/CD pipeline tasks
        containerization.yml      # Container management
    "
    
    # Infrastructure
    ["Infrastructure"]="
        cloud_management.yml      # Cloud resource management
        database_admin.yml        # Database administration
    "
    
    # Documentation
    ["Documentation"]="
        documentation.yml         # System documentation
        collaboration.yml        # Team collaboration tools
    "
)

# Main execution
check_dependencies
show_header

# Create menu options from categories
menu_options=()
for category in "${!playbook_categories[@]}"; do
    # Extract playbooks for this category
    while read -r playbook comment; do
        if [ ! -z "$playbook" ]; then
            playbook=$(echo $playbook | xargs) # Trim whitespace
            menu_options+=("$playbook" "$category: $comment" off)
        fi
    done <<< "${playbook_categories[$category]}"
done

# Display dialog menu
choices=$(dialog --clear --title "Ansible Playbook Selection" \
                --checklist "Select playbooks to run (Space to select, Enter to confirm):" \
                25 78 20 "${menu_options[@]}" 2>&1 >/dev/tty)

clear

# Execute selected playbooks
if [ -n "$choices" ]; then
    echo -e "${BLUE}Selected playbooks: $choices${NC}"
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
