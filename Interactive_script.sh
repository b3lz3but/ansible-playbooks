#!/bin/bash

# Source utility functions and logger
source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/logger.sh"

# Initialize
load_config
check_dependencies

# Validate inventory
INVENTORY=$(python3 -c 'import yaml;print(yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'"))["paths"]["inventory"])')
if [ ! -f "$INVENTORY" ]; then
    log_error "Inventory file not found: $INVENTORY"
    exit 1
fi

# Check AWX availability
check_awx_connection
AWX_AVAILABLE=$?

# Get available playbooks
mapfile -t playbooks < <(get_playbooks)

# Validate playbooks exist
if [ ${#playbooks[@]} -eq 0 ]; then
    log_error "No playbooks found!"
    exit 1
fi

# Create menu options
menu_options=()
for playbook in "${playbooks[@]}"; do
    menu_options+=("$playbook" "$(grep '^# Description:' "$PLAYBOOKS_DIR/$playbook" | cut -d':' -f2- || echo "Run $playbook")" OFF)
done

# Display selection menu
CHOICE=$(whiptail --title 'Ansible Playbook Runner' \
                  --checklist 'Select playbooks to run:' \
                  25 78 15 "${menu_options[@]}" \
                  3>&1 1>&2 2>&3)

# Handle selection
if [ $? -ne 0 ] || [ -z "$CHOICE" ]; then
    log_warning "No playbooks selected"
    exit 0
fi

# Execute selected playbooks
for playbook in $CHOICE; do
    playbook=$(echo "$playbook" | tr -d '"')
    if [ $AWX_AVAILABLE -eq 0 ]; then
        log_info "Triggering AWX job for $playbook"
        response=$(curl -s -X POST \
                       -u "$AWX_USER:$AWX_PASSWORD" \
                       -H "Content-Type: application/json" \
                       -d '{"playbook":"'"$playbook"'"}' \
                       "$AWX_URL/api/$AWX_API_VERSION/job_templates/1/launch/")
        
        if [ $? -eq 0 ]; then
            log_success "AWX job triggered successfully for $playbook"
        else
            log_error "Failed to trigger AWX job for $playbook"
        fi
    else
        log_info "Running $playbook locally"
        if ansible-playbook -i "$INVENTORY" "$PLAYBOOKS_DIR/$playbook"; then
            log_success "Successfully executed $playbook"
        else
            log_error "Failed to execute $playbook"
        fi
    fi
done

# Display AWX access information
if [ $AWX_AVAILABLE -eq 0 ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    log_info "Access AWX at: http://$SERVER_IP:8052"
fi

exit 0
