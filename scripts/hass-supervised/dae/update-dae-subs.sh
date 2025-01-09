#!/bin/sh

cd /etc/dae || { echo "/etc/dae does not exist."; exit 1; }
if [[ ! -f sublist ]]; then
    echo "The subscription file does not exist."
    exit 1
fi
if [[ -z sublist ]]; then
    echo "The subscription file is empty."
    exit 1
fi

sed -e 's/^ *//g' -e 's/ *$//g' -e 's/"//g' sublist > sublist.tmp

version="$(dae --version | head -n 1 | sed 's/dae version //')"
UA="dae/${version} (like v2rayA/1.0 WebRequestHelper) (like v2rayN/1.0 WebRequestHelper)"
fail=false
line_number=1

while IFS= read -r url
do
    if [[ -z "$url" ]]; then
        continue
    fi

    file_name="subscription_${line_number}.sub"

    if curl --retry 3 --retry-delay 5 -fL -A "$UA" "$url" -o "${file_name}.new"; then
        mv "${file_name}.new" "$file_name"
        chmod 0600 "$file_name"
        echo "Downloaded $file_name from $url"
    else
        rm -f "${file_name}.new"
        fail1=true
    fi

    line_number=$((line_number + 1))
done < sublist.tmp

rm -f sublist.tmp

if curl --retry 3 --retry-delay 5 -fL "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" -o "geoip.dat.new"; then
    mv "geoip.dat.new" "geoip.dat"
    chmod 0600 "geoip.dat"
    echo "Downloaded latest geoip.dat."
else
    rm -f "geoip.dat.new"
    fail2=true
fi

if curl --retry 3 --retry-delay 5 -fL "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" -o "geosite.dat.new"; then
    mv "geosite.dat.new" "geosite.dat"
    chmod 0600 "geosite.dat"
    echo "Downloaded latest geosite.dat."
else
    rm -f "geosite.dat.new"
    fail3=true
fi

docker exec dae reload

if [ $? -ne 0 ]; then
  echo "Reload failed, restarting dae..."
  docker restart dae
else
  echo "Reload succeeded."
fi

if $fail1; then
    echo "Failed to update subscriptions."
fi
if $fail2; then
    echo "Failed to update geoip.dat."
fi
if $fail3; then
    echo "Failed to update geosite.dat."
fi