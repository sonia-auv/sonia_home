#!/usr/bin/env bash

# -- INSTRUCTIONS: ------------------------------------------------------------
#
# Execute:
#   $ chmod u+x sonia-install.sh && ./sonia-install.sh
#
# Options:
#   -h, --help      output program instructions
#   -v, --version   output program version
#   -e, --env       set build environment variable (e.g: dev, auv7, auv8)
#
# ------------------------------------------------------------------------------
# | VARIABLES                                                                  |
# ------------------------------------------------------------------------------

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
ORANGE='\033[0;33m'
BOLD="$(tput bold)"
RESET="$(tput sgr0)"

VERSION="1.0.0"
PROGRAM="sonia-install"

AUV_ENV_SETUP_REPO_URL="git@github.com:sonia-auv/auv-env-setup.git"
AUV_ENV_SETUP_DIR="${HOME}/auv-env-setup"

SSH_KEY_FILE=${HOME}/.ssh/id_rsa


# Header logging
e_info() {
    echo "${YELLOW}[INFO]:${RESET}" "$@"
    echo " "
}

# Success logging
e_success() {
    echo "${GREEN}✔${RESET}" "$@"
    echo " "
}

# Error logging
e_error() {
    echo "${RED}[ERROR]:${RESET}" "$@"
    exit 1
}

# Warning logging
e_warning() {
    echo "${ORANGE}![WARNING]:${RESET}" "$@"
    echo " "
}

# ------------------------------------------------------------------------------
# | MAIN FUNCTIONS                                                             |
# ------------------------------------------------------------------------------

help() {

cat <<EOT

------------------------------------------------------------------------------
Start - DESCRIPTION
------------------------------------------------------------------------------

Usage: ./sonia-install.sh
Example: ./sonia-install.sh


Options:
    -h, --help       output program instructions
    -v, --version    output program version
    -e, --enviroment installation target environment [dev, auv7, auv8]
EOT

}

version() {
    echo "$PROGRAM: v$VERSION"
}

install_git() {
    if ! [ -x "$(command -v git)" ]; then
        e_info "Git is not installed ... installing"
        sudo apt-get update -qq && sudo apt-get install git -y -qq 
    else
        e_info  "Git is installed"
    fi
}

generate_ssh_key() {
     if ! [ -f "${SSH_KEY_FILE}" ]; then
        echo " "
        e_info "Generating SSH key...."
        ssh-keygen -t rsa -b 4096
        eval "$(ssh-agent -s > /dev/null)"
        ssh-add ~/.ssh/id_rsa > /dev/null
    else
        e_info "SSH key already present"
        eval "$(ssh-agent -s > /dev/null)"
        ssh-add ~/.ssh/id_rsa > /dev/null
    fi

    echo " "
    cat ~/.ssh/id_rsa.pub
    echo " "
    e_info  "Add generated ssh key to your github account than press enter to continue"

    read user_input
}

clone_auv_env_setup() {
    BUILD_ENV=${1}
    e_info "Cloning AUV environment install scripts"
    if [ -d  ${AUV_ENV_SETUP_DIR} ]; then
            rm -rf ${AUV_ENV_SETUP_DIR}
    fi

    git clone ${AUV_ENV_SETUP_REPO_URL} ${AUV_ENV_SETUP_DIR} && cd ${AUV_ENV_SETUP_DIR} && git checkout feature/create-install-script #TODO:REMOVE
    echo " "
    echo " "
    e_info "Stating AUV environment install script"

}

install_env() {
    BUILD_ENV=${1}
    e_info "Current build environment:${BUILD_ENV}"
    case ${BUILD_ENV} in
        dev|auv7|auv8)
            if [ -z "${AUV_LOCAL_ENVIRONMENT}" ]; then
		AUV_LOCAL_ENVIRONMENT=${BUILD_ENV}
                install_git
                generate_ssh_key
                clone_auv_env_setup
		
            fi
            e_info "Launching SONIA AUV installation ......."
            exec ${AUV_ENV_SETUP_DIR}/install.sh --environment ${AUV_LOCAL_ENVIRONMENT}
            ;;
        *)
            e_error "Possible environment are [dev, auv7, auv8]"
    esac
}

# ------------------------------------------------------------------------------
# | INITIALIZE SCRIPT                                                          |
# ------------------------------------------------------------------------------

main() {

    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        help ${1}
    elif [[ "${1}" == "-v" || "${1}" == "--version" ]]; then
        version ${1}
    elif [[ "${1}" == "-e" || "${1}" == "--environment" ]]; then
	    install_env ${2}
    else
         e_error "You must provide additional environment parameter to be able to launch the installation"
	fi

}
# Initialize
main $*