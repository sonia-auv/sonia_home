#!/usr/bin/env bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if the .env file exists
if [[ -f "$ENV_FILE" ]]; then
    echo ".env file already exists at $ENV_FILE"
else
    echo ".env file not found. Creating it..."
    echo "SONIA_WS=$HOME/ros2_sonia_ws" > "$ENV_FILE"
    echo "Created .env with SONIA_WS=$HOME/ros2_sonia_ws"
fi
