#!/bin/bash
# Monitoring script for Kheti Sahayak Play Store deployment
# This script checks if the upload key reset has been approved and deploys

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/playstore_manager.py"
LOG_FILE="$SCRIPT_DIR/deployment_monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_and_deploy() {
    log "Checking deployment status..."
    
    # Try to check status
    output=$(python3 "$PYTHON_SCRIPT" --check-status 2>&1)
    
    if echo "$output" | grep -q "error\|Error\|ERROR"; then
        if echo "$output" | grep -q "APK_NOT_SIGNED_WITH_EXPECTED_KEY"; then
            log "Key reset not yet approved - waiting..."
            return 1
        else
            log "Other error occurred:"
            echo "$output" | tail -20
            return 1
        fi
    else
        log "Status check passed! Attempting deployment..."
        python3 "$PYTHON_SCRIPT" --deploy --track internal
        return $?
    fi
}

# Main monitoring loop
log "Starting deployment monitor..."
log "Will check every 30 minutes"

while true; do
    if check_and_deploy; then
        log "Deployment successful! Exiting monitor."
        exit 0
    fi
    
    log "Waiting 30 minutes before next check..."
    sleep 1800
done
