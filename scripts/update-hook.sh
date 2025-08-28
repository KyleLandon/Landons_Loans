#!/bin/bash

# Landon's Loans Auto-Update Script
# Place this in your FiveM server and run it via cron or webhook

RESOURCE_PATH="/opt/fivem/server-data/resources/[qb]/LandonsLoans"
BACKUP_PATH="/opt/fivem/backups"
LOG_FILE="/var/log/landons-loans-update.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send FiveM console command
send_fivem_command() {
    local command="$1"
    # Adjust this path to your FiveM console method
    echo "$command" > /tmp/fivem_console_input.txt
    # Alternative: Use screen/tmux to send to FiveM console
    # screen -S fivem -p 0 -X stuff "$command^M"
}

# Function to backup current version
backup_current() {
    local backup_name="LandonsLoans-$(date +%Y%m%d_%H%M%S)"
    log "Creating backup: $backup_name"
    
    mkdir -p "$BACKUP_PATH"
    cp -r "$RESOURCE_PATH" "$BACKUP_PATH/$backup_name"
    
    # Keep only last 5 backups
    cd "$BACKUP_PATH"
    ls -t | grep "LandonsLoans-" | tail -n +6 | xargs rm -rf
    
    log "Backup created successfully"
}

# Main update function
update_resource() {
    log "Starting Landon's Loans update process..."
    
    # Check if resource directory exists
    if [ ! -d "$RESOURCE_PATH" ]; then
        log "ERROR: Resource directory not found: $RESOURCE_PATH"
        exit 1
    fi
    
    # Navigate to resource directory
    cd "$RESOURCE_PATH" || exit 1
    
    # Check if git repository
    if [ ! -d ".git" ]; then
        log "ERROR: Not a git repository. Please clone from GitHub first."
        exit 1
    fi
    
    # Create backup
    backup_current
    
    # Fetch latest changes
    log "Fetching latest changes from GitHub..."
    git fetch origin main
    
    # Check if there are updates
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log "No updates available. Current version is up to date."
        exit 0
    fi
    
    # Stop the resource
    log "Stopping LandonsLoans resource..."
    send_fivem_command "stop LandonsLoans"
    sleep 3
    
    # Pull latest changes
    log "Pulling latest changes..."
    if git pull origin main; then
        log "Git pull successful"
    else
        log "ERROR: Git pull failed. Rolling back..."
        git reset --hard HEAD~1
        exit 1
    fi
    
    # Check for database migrations
    if [ -f "sql/migrations.sql" ]; then
        log "Running database migrations..."
        # Add your MySQL command here
        # mysql -u username -p password database_name < sql/migrations.sql
    fi
    
    # Restart the resource
    log "Starting LandonsLoans resource..."
    send_fivem_command "refresh"
    sleep 2
    send_fivem_command "start LandonsLoans"
    
    # Get new version info
    NEW_VERSION=$(git describe --tags --always)
    log "Update completed successfully! New version: $NEW_VERSION"
    
    # Optional: Send notification
    if command -v curl >/dev/null 2>&1 && [ ! -z "$DISCORD_WEBHOOK" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\"🏦 **Landon's Loans** updated to version \`$NEW_VERSION\` on $(hostname)\"}" \
             "$DISCORD_WEBHOOK"
    fi
}

# Run the update
update_resource

log "Update process completed."
