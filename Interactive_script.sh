#!/bin/bash

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/logger.sh"

load_config
check_dependencies

INVENTORY="/ansible/inventory.ini"
PLAYBOOKS_DIR="/ansible/playbooks"

# Get available playbooks
mapfile -t playbooks < <(find "$PLAYBOOKS_DIR" -name "*.yml" -exec basename {} \;)

if [ ${#playbooks[@]} -eq 0 ]; then
    log_error "No playbooks found!"
    exit 1
fi

echo "Available playbooks:"
select CHOICE in "${playbooks[@]}"; do
    if [[ -n "$CHOICE" ]]; then
        break
    fi
    echo "Invalid selection. Try again."
done

PLAYBOOK_PATH="$PLAYBOOKS_DIR/$CHOICE"
if ansible-playbook -i "$INVENTORY" "$PLAYBOOK_PATH"; then
    log_success "Successfully executed $CHOICE"
else
    log_error "Failed to execute $CHOICE"
fi

exit 0
