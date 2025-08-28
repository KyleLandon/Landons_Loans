#!/bin/bash

# FiveM RCON Integration for Resource Management
# Requires your FiveM server to have RCON enabled

RCON_HOST="localhost"
RCON_PORT="30120"
RCON_PASSWORD="your-rcon-password"

# Function to send RCON command
send_rcon() {
    local command="$1"
    
    # Using mcrcon tool (install with: sudo apt install mcrcon)
    if command -v mcrcon >/dev/null 2>&1; then
        mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$command"
    else
        # Alternative: use netcat
        echo "$command" | nc "$RCON_HOST" "$RCON_PORT"
    fi
}

# Restart LandonsLoans resource
restart_resource() {
    echo "Restarting LandonsLoans via RCON..."
    send_rcon "stop LandonsLoans"
    sleep 3
    send_rcon "refresh"
    sleep 2
    send_rcon "start LandonsLoans"
    echo "Resource restarted successfully"
}

# Call the function
restart_resource
