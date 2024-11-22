#!/bin/bash

cd /etc/dae || { echo "/etc/dae does not exist."; exit 1; }

if [[ ! -f sublist ]]; then
    echo "sublist file does not exist."
    exit 1
fi

version="$(dae --version | head -n 1 | sed 's/dae version //')"
UA="dae/${version} (like v2rayA/1.0 WebRequestHelper) (like v2rayN/1.0 WebRequestHelper)"
fail=false

while IFS=':' read -r name url
do
    if curl --retry 3 --retry-delay 5 -fL -A "$UA" "$url" -o "${name}.sub.new"; then
        mv "${name}.sub.new" "${name}.sub"
        chmod 0600 "${name}.sub"
        echo "Downloaded $name"
    else
        rm "${name}.sub.new"
        fail=true
        echo "Failed to download $name"
    fi
done < sublist

dae reload

if $fail; then
    echo "Failed to update subs"
    exit 2
fi