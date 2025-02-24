#!/bin/bash

CONFIG_FILE="$(dirname "$0")/config.yaml"

# Check if the configuration file exists before proceeding
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Load colors from config
eval $(python3 -c 'import yaml;print("\n".join([f"{k.upper()}=\"{v}\"" for k,v in yaml.safe_load(open("'"$CONFIG_FILE"'"))["display"]["colors"].items()]))')

# Load log file path
LOG_FILE=$(python3 -c 'import yaml;print(yaml.safe_load(open("'"$CONFIG_FILE"'"))["paths"]["logs"])/ansible-runner.log')

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
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

# Ensure log rotation (optional)
rotate_logs() {
    local max_size=10485760 # 10MB
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $max_size ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        log_info "Log rotated: $LOG_FILE.old"
    fi
}

# Ensure the log file exists
touch "$LOG_FILE"
rotate_logs
