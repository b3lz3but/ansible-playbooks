#!/usr/bin/env bash

# Enable strict mode for safety
set -euo pipefail
IFS=$'\n\t'
# Debug mode is disabled for production
# set -x

# Constants with improved organization
declare -r MAX_RETRIES=30
declare -r WAIT_SECONDS=5
declare -ra REQUIRED_PACKAGES=("postgresql-client" "ansible" "curl")
declare -ra REQUIRED_ENV_VARS=("AWX_DB_HOST" "AWX_DB_PORT" "AWX_DB_USER" "AWX_DB_PASSWORD" "AWX_DB_NAME")
declare -r AWX_PORT=8052
declare -r AWX_INSTALLER_DIR="/opt/awx/installer"
declare -r AWX_UTILS="/opt/awx/utils.sh"
declare -r AWX_LOGGER="/opt/awx/logger.sh"

# Function to print status messages with timestamp and color
print_status() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        "INFO")  echo -e "\n[\033[0;32m${timestamp}\033[0m] 📢 ${message}" ;;
        "WARN")  echo -e "\n[\033[0;33m${timestamp}\033[0m] ⚠️ ${message}" ;;
        "ERROR") echo -e "\n[\033[0;31m${timestamp}\033[0m] ❌ ${message}" ;;
         *)      echo -e "\n[${timestamp}] ${message}" ;;
    esac
}

# Function to check required environment variables
check_env_vars() {
    local missing_vars=()
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_status "ERROR" "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    print_status "INFO" "Environment validation successful"
}

# Function to check and install required packages
check_dependencies() {
    local missing_packages=()
    for cmd in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_packages+=("$cmd")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_status "WARN" "Installing missing packages: ${missing_packages[*]}"
        if ! apt-get update && apt-get install -y "${missing_packages[@]}"; then
            print_status "ERROR" "Failed to install required packages!"
            exit 1
        fi
    fi
    print_status "INFO" "All dependencies are satisfied"
}

# Function to wait for PostgreSQL
wait_for_postgres() {
    local counter=0
    print_status "INFO" "🔍 Checking PostgreSQL connectivity..."
    while ! PGPASSWORD="${AWX_DB_PASSWORD}" psql -h "${AWX_DB_HOST}" -p "${AWX_DB_PORT}" -U "${AWX_DB_USER}" -d "${AWX_DB_NAME}" -c '\l' >/dev/null 2>&1; do
        ((counter++))
        if [[ "$counter" -ge "$MAX_RETRIES" ]]; then
            print_status "ERROR" "PostgreSQL is not available after $MAX_RETRIES attempts"
            exit 1
        fi
        print_status "INFO" "⏳ Waiting for PostgreSQL... (Attempt: ${counter}/${MAX_RETRIES})"
        sleep "$WAIT_SECONDS"
    done
    print_status "INFO" "✅ PostgreSQL is available"
}

# Function to wait for AWX services (using the same endpoint as defined in docker-compose)
wait_for_awx() {
    local timeout=300  # 5 minutes timeout
    local start_time
    start_time=$(date +%s)

    while true; do
        if curl -fsSL "http://127.0.0.1:${AWX_PORT}/api/v2/ping/" >/dev/null 2>&1; then
            print_status "INFO" "✅ AWX is up and running!"
            return 0
        fi

        if (( $(date +%s) - start_time >= timeout )); then
            print_status "ERROR" "AWX failed to start within ${timeout} seconds"
            exit 1
        fi

        print_status "INFO" "⌛ Waiting for AWX... ($(( $(date +%s) - start_time ))/${timeout}s)"
        sleep 10
    done
}

# Main execution
main() {
    # Cleanup function to handle shutdown signals
    cleanup() {
        print_status "INFO" "🔄 Shutting down gracefully..."
        kill "$(jobs -p)" 2>/dev/null || true
        exit 0
    }

    trap cleanup TERM INT

    print_status "INFO" "🚀 Starting AWX installation process"

    # Load utility scripts
    for script in "$AWX_UTILS" "$AWX_LOGGER"; do
        if [[ -f "$script" ]]; then
            source "$script"
        else
            print_status "ERROR" "Required script $script not found!"
            exit 1
        fi
    done

    check_env_vars
    check_dependencies
    wait_for_postgres

    # Verify AWX installer directory exists
    if [[ ! -d "$AWX_INSTALLER_DIR" ]]; then
        print_status "ERROR" "AWX installer directory not found!"
        exit 1
    fi

    cd "$AWX_INSTALLER_DIR" || exit 1

    if [[ ! -f "install.yml" ]]; then
        print_status "ERROR" "install.yml playbook is missing!"
        exit 1
    fi

    print_status "INFO" "📦 Running AWX installation playbook"
    if ! ansible-playbook -vvv -i inventory install.yml; then
        print_status "ERROR" "AWX installation failed! Check logs for details."
        exit 1
    fi

    wait_for_awx

    local ip_address
    ip_address=$(hostname -I | awk '{print $1}')

    print_status "INFO" "✅ AWX installation completed successfully!"
    print_status "INFO" "🌍 AWX is available at: http://${ip_address}:${AWX_PORT}"
    print_status "INFO" "👉 Default credentials: admin / password"
    print_status "INFO" "📝 Please change the default password after first login"

    # Keep container running
    sleep infinity & wait
}

# Execute main function
main "$@"
