#!/bin/bash

CONFIG_FILE="$(dirname "$0")/config.yaml"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found at $CONFIG_FILE"
    echo "🔹 Hint: Ensure that 'config.yaml' exists in $(dirname "$0")"
    exit 1
fi

# Load colors from config safely
COLORS=$(python3 -c "
import yaml
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
        colors = config.get('display', {}).get('colors', {})
        print('\n'.join([f'{k.upper()}=\"{v}\"' for k, v in colors.items()]))
except Exception as e:
    print('ERROR: Failed to parse config.yaml:', e)
    exit(1)
")

# If there was an error parsing config.yaml, exit
if echo "$COLORS" | grep -q "ERROR:"; then
    exit 1
fi

eval "$COLORS"

# Load log file path safely
LOG_FILE=$(python3 -c "
import yaml
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = yaml.safe_load(f)
        print(config.get('paths', {}).get('logs', '') + '/ansible-runner.log')
except Exception as e:
    print('ERROR: Failed to retrieve log file path:', e)
    exit(1)
")

# Ensure log file path is valid
if [[ -z "$LOG_FILE" || "$LOG_FILE" == "ERROR:"* ]]; then
    echo "❌ ERROR: Invalid log file path from config.yaml"
    exit 1
fi

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
