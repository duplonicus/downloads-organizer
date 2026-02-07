#!/bin/bash

# install-cron.sh
# Installs the Organize Downloads cron job for automatic daily execution.

# --- Configuration ---
SCRIPT_NAME="organize-downloads.sh"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SCRIPT_NAME"
CRON_SCHEDULE="0 18 * * *"  # Daily at 6:00 PM

# Check if script exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: Could not find '$SCRIPT_NAME' in the current directory."
    exit 1
fi

# Make script executable
chmod +x "$SCRIPT_PATH"
echo "Script is now executable: $SCRIPT_PATH"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "Cron job already exists for this script."
    echo "To modify the schedule, run: crontab -e"
    exit 0
fi

# Add cron job
(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $SCRIPT_PATH") | crontab -

if [[ $? -eq 0 ]]; then
    echo "------------------------------------------------"
    echo "Success! Cron job has been installed."
    echo "Schedule: Daily at 6:00 PM (0 18 * * *)"
    echo "Script: $SCRIPT_PATH"
    echo ""
    echo "To verify:"
    echo "  crontab -l"
    echo ""
    echo "To modify the schedule:"
    echo "  crontab -e"
    echo ""
    echo "To remove the cron job:"
    echo "  crontab -r"
    echo "------------------------------------------------"
else
    echo "Error: Failed to install cron job."
    echo "Make sure cron service is running on your system."
    exit 1
fi
