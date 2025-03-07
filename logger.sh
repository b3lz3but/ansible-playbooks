#!/bin/bash

LOG_FILE="/var/log/ansible/ansible-runner.log"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info()    { log_message "INFO" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_error()   { log_message "ERROR" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
