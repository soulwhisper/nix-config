#!/bin/bash

DEFAULT_DIR="/opt/apps/hass"

# Function to check if the script is run as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root. Attempting to gain root privileges using sudo ..."
        if command -v sudo &>/dev/null; then
            sudo "$0" "$@"
            exit 0
        else
            echo "Error: sudo is not installed. Please run this script as root."
            exit 1
        fi
    fi
    echo "Running as root."
}

# Function to set proxy environment variables if defined
set_proxy() {
    echo "Configuring proxy settings (if defined) ..."
    if [[ -n "$http_proxy" ]]; then
        export http_proxy="$http_proxy"
        echo "Using HTTP proxy: $http_proxy"
    fi
    if [[ -n "$https_proxy" ]]; then
        export https_proxy="$https_proxy"
        echo "Using HTTPS proxy: $https_proxy"
    fi
    if [[ -n "$all_proxy" ]]; then
        export all_proxy="$all_proxy"
        echo "Using ALL proxy: $all_proxy"
    fi
    echo "Proxy settings applied."
}

# Function to load environment variables from .env file
load_env() {
    ENV_FILE="$(dirname "$0")/.env"
    if [[ -f "$ENV_FILE" ]]; then
        echo "Loading configuration from $ENV_FILE..."
        export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
        echo "Configuration loaded successfully."
    else
        echo "Error: .env file not found in $(dirname "$0"). Please create a .env file with the necessary variables."
        exit 1
    fi

    # Ensure necessary environment variables are set
    if [[ -z "$RESTIC_PASSWORD" || -z "$RESTIC_REPOSITORY" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "Error: RESTIC_PASSWORD, RESTIC_REPOSITORY, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY must be defined in the .env file."
        exit 1
    fi
}

# Function to check if Docker is installed
check_docker_installed() {
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Please run install.sh first."
    else
        echo "Docker is already installed."
    fi
}

# Function to configure dae
configure_dae() {
    cp -r dae /etc/
    cp /etc/dae/update-dae-subs.timer /etc/systemd/system/update-dae-subs.timer
    cp /etc/dae/update-dae-subs.service /etc/systemd/system/update-dae-subs.service

    chmod 0600 /etc/dae/sublist

    docker run -d \
        --restart always \
        --network host \
        --pid host \
        --privileged \
        -v /sys:/sys \
        -v /etc/dae:/etc/dae \
        --name dae \
        daeuniverse/dae:latest
}

# Function to configure restic
configure_restic() {
    echo "Install or Update restic ..."

    apt-get update
    apt-get install -y restic

    echo "Configuring restic for Cloudflare R2..."

    # Create default sync directory
    mkdir -p "$DEFAULT_DIR"

    # Initialize restic repository on Cloudflare R2 if not already configured
    if ! restic snapshots -r "$RESTIC_REPOSITORY" &>/dev/null; then
        echo "Initializing restic repository on Cloudflare R2 ..."
        restic init -r "$RESTIC_REPOSITORY"
        echo "Restic repository initialized successfully with Cloudflare R2."
    else
        echo "Restic repository already configured with Cloudflare R2."
    fi

    # Add to crontab for periodic backup
    CRON_JOB="0 2 * * * RESTIC_PASSWORD='$RESTIC_PASSWORD' AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY_ID' AWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY' restic backup -r $RESTIC_REPOSITORY $DEFAULT_DIR"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Scheduled daily backup of $DEFAULT_DIR at 2:00 AM."
}

# Main function
main() {
    check_root "$@"
    set_proxy
    install_dependencies
    load_env
    check_docker_installed
    configure_dae
    configure_restic
    echo "Configuration complete. Restic is set to back up $DEFAULT_DIR."
}

# Run the main function
main "$@"
