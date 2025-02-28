#!/bin/bash

# Assume CONFIG_FILE is already defined in the environment or via utils.sh
# Otherwise, you can uncomment the following line to set it:
# CONFIG_FILE="/opt/awx/config.yaml"

CONFIG_LOGGER_FILE=$(dirname "$0")/config.yaml

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Load colors from config and remove any null bytes from the values
eval $(python3 -c 'import yaml; 
colors = yaml.safe_load(open("'"$CONFIG_FILE"'")).get("display", {}).get("colors", {}); 
print("\n".join([f"{k.upper()}=\'{v.replace(chr(0), "")}\'" for k, v in colors.items()]))')

# Load log file path from config.yaml (using the "paths" block at the bottom)
LOG_FILE=$(python3 -c 'import yaml; print(yaml.safe_load(open("'"$CONFIG_FILE"'")).get("paths", {}).get("logs", "/var/log") + "/ansible-runner.log")')

# Check if the log directory is writable; if not, use a fallback directory
LOG_DIR=$(dirname "$LOG_FILE")
if [ ! -w "$LOG_DIR" ]; then
    echo "Directory $LOG_DIR is not writable. Falling back to /opt/awx/logs."
    mkdir -p /opt/awx/logs
    LOG_FILE="/opt/awx/logs/ansible-runner.log"
fi

# Create the log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    echo -e "${INFO}ℹ️ $1${RESET}"
    log_message "INFO" "$1"
}

log_success() {
    echo -e "${SUCCESS}✅ $1${RESET}"
    log_message "SUCCESS" "$1"
}

log_error() {
    echo -e "${ERROR}❌ $1${RESET}"
    log_message "ERROR" "$1"
}

log_warning() {
    echo -e "${WARNING}⚠️ $1${RESET}"
    log_message "WARNING" "$1"
}

# Optional: Log rotation function
rotate_logs() {
    local max_size=10485760  # 10MB
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        log_info "Log rotated: $LOG_FILE.old"
    fi
}

# Ensure the log file exists
touch "$LOG_FILE"
rotate_logs
