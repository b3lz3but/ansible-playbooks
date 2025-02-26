#!/bin/bash

set -euo pipefail  # Add error handling and strict mode

# Constants
readonly CONFIG_FILE="/opt/awx/config.yaml"

# Logging functions with timestamps
log_info() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') 🟢 INFO: $1"
}

log_warning() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') 🟠 WARNING: $1"
}

log_error() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') 🔴 ERROR: $1"
}

log_success() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') ✅ SUCCESS: $1"
}

# Check if config file exists
check_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
}

# Load configuration with error handling
load_config() {
    check_config_file
    
    if ! python3 -c 'import yaml' 2>/dev/null; then
        log_error "Python YAML module not installed"
        exit 1
    fi

    local config_vars
    config_vars=$(python3 -c 'import yaml,os; print("\n".join([f"{k.upper()}=\"{v}\"" for k,v in yaml.safe_load(open("'"$CONFIG_FILE"'")).get("awx",{}).items()]))') || {
        log_error "Failed to parse config file"
        exit 1
    }
    
    eval "$config_vars"
}

# Check for required dependencies with timeout
check_dependencies() {
    check_config_file
    
    local missing_deps=()
    local TIMEOUT=300  # 5 minutes timeout for installation
    
    while read -r dep; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done < <(python3 -c 'import yaml; print("\n".join(yaml.safe_load(open("'"$CONFIG_FILE"'"))["dependencies"]["required"]))')

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_info "Installing missing dependencies: ${missing_deps[*]}"
        timeout $TIMEOUT apt-get update && apt-get install -y "${missing_deps[@]}" || {
            log_error "Failed to install dependencies"
            exit 1
        }
    fi
}

# Validate AWX connectivity with timeout
check_awx_connection() {
    local TIMEOUT=10
    
    if timeout $TIMEOUT curl -sf --head "$AWX_URL" &>/dev/null; then
        log_success "AWX is available at $AWX_URL"
        return 0
    else
        log_warning "AWX is not available at $AWX_URL. Using local execution."
        return 1
    fi
}

# Get available playbooks with validation
get_playbooks() {
    check_config_file
    
    local playbooks_dir
    playbooks_dir=$(python3 -c 'import yaml; print(yaml.safe_load(open("'"$CONFIG_FILE"'"))["paths"]["playbooks"])') || {
        log_error "Failed to get playbooks directory"
        exit 1
    }

    if [ ! -d "$playbooks_dir" ]; then
        log_error "Playbooks directory not found: $playbooks_dir"
        exit 1
    fi

    find "$playbooks_dir" -name "*.yml" -type f -exec basename {} \; || {
        log_error "Failed to list playbooks"
        exit 1
    }
}

# Service check functions with timeout
ensure_service_running() {
    local service_name="$1"
    local check_command="$2"
    local TIMEOUT=30
    
    log_info "Checking if $service_name is running..."

    if ! eval "$check_command"; then
        log_warning "$service_name is not running! Attempting to start..."
        systemctl restart "$service_name" || {
            log_error "Failed to restart $service_name"
            exit 1
        }
        
        sleep 5
        
        timeout $TIMEOUT bash -c "until eval '$check_command'; do sleep 1; done" || {
            log_error "Failed to start $service_name"
            exit 1
        }
    fi
    log_success "$service_name is running"
}

# Updated service check functions
ensure_awx_running() {
    ensure_service_running "awx" "pgrep -f 'awx-manage' > /dev/null"
}

ensure_postgres_running() {
    ensure_service_running "postgresql" "pg_isready -h \"$AWX_DB_HOST\" -U \"$AWX_DB_USER\" > /dev/null 2>&1"
}
