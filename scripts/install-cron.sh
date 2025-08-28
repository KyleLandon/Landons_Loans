#!/bin/bash

# Install auto-update cron job for Landon's Loans

SCRIPT_PATH="/opt/fivem/scripts/update-hook.sh"

# Make update script executable
chmod +x "$SCRIPT_PATH"

# Add cron job (every 10 minutes)
(crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_PATH >/dev/null 2>&1") | crontab -

echo "✅ Cron job installed successfully!"
echo "Landon's Loans will check for updates every 10 minutes."

# Show current crontab
echo ""
echo "Current cron jobs:"
crontab -l
