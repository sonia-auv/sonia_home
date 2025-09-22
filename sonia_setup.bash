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
    echo "Added SONIA_WS=$HOME/ros2_sonia_ws to .env file"
    
    UBUNTU_VERSION=$(lsb_release -rs)

    if [[ "$UBUNTU_VERSION" == "20.04" ]]; then
        # echo "Detected Ubuntu 20.04"
        # Do 20.04-specific stuff here
        export ROS_WS_SETUP=~/ros2_humble/install/setup.bash
        echo "ROS_WS_SETUP=$HOME/ros2_humble/install/setup.bash" >> "$ENV_FILE"
        echo "Added ROS_WS_SETUP=$HOME/ros2_humble/install/setup.bash to .env file"

    elif [[ "$UBUNTU_VERSION" == "22.04" ]]; then
        # echo "Detected Ubuntu 22.04"
        echo "ROS_WS_SETUP=/opt/ros/humble/setup.bash" >> "$ENV_FILE"
        echo "Added ROS_WS_SETUP=/opt/ros/humble/setup.bash to .env file"
    else
        echo "Warning: Unsupported Ubuntu version ($UBUNTU_VERSION)"
    fi
    echo "Created .env with SONIA_WS=$HOME/ros2_sonia_ws"
fi
