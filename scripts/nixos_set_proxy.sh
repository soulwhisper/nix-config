#!/usr/bin/env bash

# usage
# bash nixos_set_proxy.sh set http://127.0.0.1:1080
# bash nixos_set_proxy.sh unset

OPTION=$1
PROXY=$2

if [ "$OPTION" == "set" ]; then
echo "set nixos proxy ..."
mkdir -p /run/systemd/system/nix-daemon.service.d/
cat << EOF >/run/systemd/system/nix-daemon.service.d/proxy-override.conf  
[Service]
Environment="http_proxy=$PROXY"
Environment="https_proxy=$PROXY"
Environment="all_proxy=$PROXY"
EOF
fi

if [ "$OPTION" == "unset" ]; then
echo "unset nixos proxy ..."
rm /run/systemd/system/nix-daemon.service.d/proxy-override.conf
fi

systemctl daemon-reload
systemctl restart nix-daemon
echo "completed."