#!/bin/bash

# Load colors from config
eval $(python3 -c 'import yaml;print("\n".join([f"{k.upper()}=\"{v}\"" for k,v in yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'"))["display"]["colors"].items()]))')

LOG_FILE=$(python3 -c 'import yaml;print(yaml.safe_load(open("'"$(dirname "$0")/config.yaml"'"))["paths"]["logs"])/ansible-runner.log')

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
    echo -e "${ERROR}⚠️ $1${RESET}"
    log_message "WARNING" "$1"
}
