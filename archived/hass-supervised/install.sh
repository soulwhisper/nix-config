#!/bin/bash

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

# Function to check if the system is Debian 12 (Bookworm)
check_system() {
    echo "Checking system information ..."
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "debian" && "$VERSION_CODENAME" == "bookworm" ]]; then
            echo "System check passed: Debian 12 (Bookworm)"
            return 0
        else
            echo "Warning: The current system is not Debian 12 (Bookworm)."
            echo "It is recommended to use Debian 12 for official support. Continuing may result in unexpected issues."
            read -p "Do you want to proceed anyway? (y/N): " confirm
            [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
        fi
    else
        echo "Unable to detect system information. Please ensure you are running Debian 12 (Bookworm)."
        exit 1
    fi
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

# Function to update the system and install required dependencies
install_dependencies() {
    echo "Updating system and installing dependencies ..."
    apt-get update
    apt-get upgrade -y
    apt-get install -y \
        apparmor \
        apt-transport-https \
        bash \
        bluez \
        ca-certificates \
        cifs-utils \
        curl \
        dbus \
        jq \
        libglib2.0-bin \
        lsb-release \
        network-manager \
        socat \
        software-properties-common \
        systemd-journal-remote \
        systemd-resolved \
        wget \
        udisks2
    echo "Dependencies installed successfully."
    echo "Home Assistant Supervised let network-manager manage current network interface."
    read -p "Do you manage interfaces using network-manager? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
}

# Function to install Docker
install_docker() {
    echo "Installing Docker ..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    echo "Docker installed successfully."
}

# Function to install Home Assistant Supervised
install_home_assistant_supervised() {
    echo "Installing Home Assistant Supervised to /opt/apps/hass ..."
    wget -O os-agent.deb https://github.com/home-assistant/os-agent/releases/latest/download/os-agent_1.6.0_linux_x86_64.deb
    wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
    mkdir -p /opt/apps/hass
    dpkg -i os-agent.deb
    apt-get install -y libevent-core-2.1-7 libnfsidmap1 nfs-common rpcbind
    DATA_SHARE=/opt/apps/hass dpkg --force-confdef --force-confold -i homeassistant-supervised.deb
    echo "Home Assistant Supervised installation completed."
}

# Main function
main() {
    check_root "$@"
    check_system
    set_proxy
    install_dependencies
    install_docker
    install_home_assistant_supervised
    echo "Installation complete! You can now access Home Assistant at http://<your-ip>:8123."
}

# Run the main function
main "$@"
