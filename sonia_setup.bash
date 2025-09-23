#!/usr/bin/env bash

########################### ENV VARIABLES ###############################################
echo "########## SETUP ENV VARIABLES"
echo
# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if the .env file exists
if [[ -f "$ENV_FILE" ]]; then
    echo ".env file already exists"
else
    echo ".env file not found. Creating it..."
    # Ask for custom SONIA_WS path (default = ~/ros2_sonia_ws)
    read -p "Enter SONIA_WS path [default: $HOME/ros2_sonia_ws]: " custom_path
    SONIA_WS_PATH="${custom_path:-$HOME/ros2_sonia_ws}"

    echo "SONIA_WS=$SONIA_WS_PATH" > "$ENV_FILE"
    echo "Added SONIA_WS=$SONIA_WS_PATH to .env file"
    
    UBUNTU_VERSION=$(lsb_release -rs)

    if [[ "$UBUNTU_VERSION" == "20.04" ]]; then
        # echo "Detected Ubuntu 20.04"
        # Do 20.04-specific stuff here
        # Ask for custom ROS_WS_SETUP path (default = ~/ros2_humble/install/setup.bash)
        read -p "Enter ROS_WS_SETUP path [default: $HOME/ros2_humble/install/setup.bash]: " custom_ros_path
        ROS_WS_SETUP_PATH="${custom_ros_path:-$HOME/ros2_humble/install/setup.bash}"

        # Expand ~ if entered
        ROS_WS_SETUP_PATH=$(eval echo "$ROS_WS_SETUP_PATH")

        # Export and write to .env
        export ROS_WS_SETUP="$ROS_WS_SETUP_PATH"
        echo "ROS_WS_SETUP=$ROS_WS_SETUP_PATH" >> "$ENV_FILE"
        echo "Added ROS_WS_SETUP=$ROS_WS_SETUP_PATH to .env file"

    elif [[ "$UBUNTU_VERSION" == "22.04" ]]; then
        # echo "Detected Ubuntu 22.04"
        echo "ROS_WS_SETUP=/opt/ros/humble/setup.bash" >> "$ENV_FILE"
        echo "Added ROS_WS_SETUP=/opt/ros/humble/setup.bash to .env file"
    else
        echo "Warning: Unsupported Ubuntu version ($UBUNTU_VERSION)"
    fi
    echo "Created .env with SONIA_WS=$HOME/ros2_sonia_ws"
fi

##################### ADD TO BASHRC ###########################

BASHRC="$HOME/.bashrc"
SOURCE_LINE="source $SCRIPT_DIR/.bash_sonia"

# Append to .bashrc only if not already present
if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "Added '$SOURCE_LINE' to $BASHRC"
else
    echo "'$SOURCE_LINE' already in $BASHRC"
fi

source "$HOME/.bashrc"

echo 

######################### SSH KEY ############################
echo "########## SETUP SSH KEY"
echo 

KEY_PATH="$HOME/.ssh/id_ed25519"

if [[ -f "$KEY_PATH" ]]; then
    echo "SSH key already exists at $KEY_PATH"
else
    echo "No SSH key found at $KEY_PATH."
    read -p "Do you want to generate a new SSH key now? (y/n): " answer
    case "$answer" in
        [Yy]* )
            read -p "Enter your email address for the SSH key (-C): " email
            mkdir -p "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
            echo "Generating new ed25519 SSH key..."
            ssh-keygen -t ed25519 -C "$email" -f "$KEY_PATH"
            echo "SSH key generated at $KEY_PATH"
            echo "Public key:"
            cat "$KEY_PATH.pub"
            
            ;;
        * )
            echo "Skipping SSH key generation."
            ;;
    esac
fi
echo "Please add to your github account. Press enter to continue when done..."
read

echo
######################### Validate Github connection ###########################
echo "########## VALIDATE GITHUB CONNECTION"
echo 
URL="git@github.com:sonia-auv/sonia_home.git"
echo "$Testing pull access via SSH: $URL"
set +e
OUT="$(git ls-remote "$URL")"
STATUS=$?
set -e

if [[ $STATUS -ne 0 ]]; then
  echo -e "FAILED ($STATUS)"
  exit 0
fi

echo "SUCCESS: Able to list refs (pull access OK)."

echo

###################### CREATE WS ###########################
echo "########## CREATE WORKSPACE"
echo
if [[ ! -d "$SONIA_WS" ]]; then
    echo "Creating SONIA_WS directory at $SONIA_WS"
    mkdir -p "$SONIA_WS/src"
else
    echo "Directory already exists"
fi

echo

#################### ADDING PROJECTS
echo "########## ADD PROJECTS"
echo 

read -p "Do you want to clone all default SONIA projects into $SONIA_WS/src? (y/n): " clone_answer
case "$clone_answer" in
    [Yy]* )
        echo "Cloning default projects..."
        
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECTS_FILE="$SCRIPT_DIR/.projects"

        if ! ssh-add -l | grep -q "$(ssh-keygen -lf ~/.ssh/id_ed25519 | awk '{print $2}')"; then
            echo "Your SSH key is not loaded into ssh-agent."
            echo "Please enter your passphrase once:"
            ssh-add ~/.ssh/id_ed25519
        fi

        cd "$SONIA_WS/src"
        while IFS= read -r line || [ -n "$line" ]; do
            proj="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            [ -z "$proj" ] && continue
            [[ "$proj" =~ ^# ]] && continue
            # echo $proj
            if [[ -d "$proj" ]]; then
                echo "$proj already exists, skipping..."
            else
                git clone git@github.com:sonia-auv/$proj.git
            fi      
        done < "$PROJECTS_FILE"
        echo "All default projects cloned."
       
       ;;
    * )
        echo "Skipping cloning. You can manually add projects later in $SONIA_WS/src."
        ;;
esac
cd "$SCRIPT_DIR"

echo

######################### BUILD PROJECTS
echo "########## ADD PROJECTS"
echo 

read -p "Do you want to build all projects? This may take a long time. (y/n): " build_answer
case "$build_answer" in
    [Yy]* )
        echo "Building projects"
        source ./.bash_sonia
        cd "$SONIA_WS/src"
        
        sonia_build -d -c

       ;;
    * )
        echo "Skipping build. You can manually projects projects later."
        ;;
esac

cd "$SCRIPT_DIR"
echo