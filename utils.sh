#!/bin/bash

source "$(dirname "$0")/logger.sh"

# Load configuration
load_config() {
    if [ ! -f "$(dirname "$0")/config.yaml" ]; then
        log_error "Configuration file not found!"
        exit 1
    }
    eval $(python3 -c 'import yaml,os;print("\n".join([f"{k.upper()}=\"{v}\"" for k,v in yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'")).get("awx",{}).items()]))')
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    while read -r dep; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done < <(python3 -c 'import yaml;print("\n".join(yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'"))["dependencies"]["required"]))')

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_info "Installing missing dependencies: ${missing_deps[*]}"
        apt-get update && apt-get install -y "${missing_deps[@]}"
    fi
}

# Validate AWX connectivity
check_awx_connection() {
    if curl -s --head "$AWX_URL" | grep "200 OK" > /dev/null; then
        log_success "AWX is available at $AWX_URL"
        return 0
    else
        log_warning "AWX is not available. Using local execution."
        return 1
    fi
}

# Get available playbooks
get_playbooks() {
    local playbooks_dir=$(python3 -c 'import yaml;print(yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'"))["paths"]["playbooks"])')
    if [ ! -d "$playbooks_dir" ]; then
        log_error "Playbooks directory not found: $playbooks_dir"
        exit 1
    fi
    find "$playbooks_dir" -name "*.yml" -type f -exec basename {} \;
}
