#!/bin/bash

set -euo pipefail

CONFIG_FILE="/ansible/config.yaml"

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

load_config() {
    if ! python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" &>/dev/null; then
        log_error "Invalid YAML configuration."
        exit 1
    fi
}

check_dependencies() {
    local deps=(ansible sshpass python3-yaml jq curl)
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
    log_success "All dependencies are installed"
}
