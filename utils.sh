#!/bin/bash

source "$(dirname "$0")/logger.sh"

# Load configuration
load_config() {
    CONFIG_FILE="$(dirname "$0")/config.yaml"

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "❌ ERROR: Configuration file not found!"
        exit 1
    fi

    eval $(python3 -c 'import yaml,os; print("\n".join([f"{k.upper()}=\"{v}\"" for k,v in yaml.safe_load(open("'"$CONFIG_FILE"'")).get("awx",{}).items()]))')
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    CONFIG_FILE="$(dirname "$0")/config.yaml"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "❌ ERROR: Configuration file not found!"
        exit 1
    fi

    while read -r dep; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done < <(python3 -c 'import yaml; print("\n".join(yaml.safe_load(open("'"$CONFIG_FILE"'"))["dependencies"]["required"]))')

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_info "📢 Installing missing dependencies: ${missing_deps[*]}"
        apt-get update && apt-get install -y "${missing_deps[@]}"
    fi
}

# Validate AWX connectivity
check_awx_connection() {
    if curl -s --head "$AWX_URL" | grep "200 OK" > /dev/null; then
        log_success "✅ AWX is available at $AWX_URL"
        return 0
    else
        log_warning "⚠️ AWX is not available. Using local execution."
        return 1
    fi
}

# Get available playbooks
get_playbooks() {
    CONFIG_FILE="$(dirname "$0")/config.yaml"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "❌ ERROR: Configuration file not found!"
        exit 1
    fi

    local playbooks_dir=$(python3 -c 'import yaml; print(yaml.safe_load(open("'"$CONFIG_FILE"'"))["paths"]["playbooks"])')

    if [ ! -d "$playbooks_dir" ]; then
        log_error "❌ ERROR: Playbooks directory not found: $playbooks_dir"
        exit 1
    fi

    find "$playbooks_dir" -name "*.yml" -type f -exec basename {} \;
}

# Ensure AWX services are running
ensure_awx_running() {
    log_info "📢 Checking if AWX is running..."

    if ! pgrep -f "awx-manage" > /dev/null; then
        log_warning "⚠️ AWX is not running! Attempting to start..."
        systemctl restart awx
        sleep 5

        if ! pgrep -f "awx-manage" > /dev/null; then
            log_error "❌ ERROR: Failed to start AWX!"
            exit 1
        fi
    fi
    log_success "✅ AWX is running."
}

# Ensure PostgreSQL is running
ensure_postgres_running() {
    log_info "📢 Checking if PostgreSQL is running..."

    if ! pg_isready -h "$AWX_DB_HOST" -U "$AWX_DB_USER" > /dev/null 2>&1; then
        log_warning "⚠️ PostgreSQL is not available! Attempting to start..."
        systemctl restart postgresql
        sleep 5

        if ! pg_isready -h "$AWX_DB_HOST" -U "$AWX_DB_USER" > /dev/null 2>&1; then
            log_error "❌ ERROR: Failed to start PostgreSQL!"
            exit 1
        fi
    fi
    log_success "✅ PostgreSQL is running."
}
