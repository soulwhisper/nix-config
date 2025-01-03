#!/bin/bash

ERROR_LOG="/tmp/nix-build-err.log"
VENDOR_HASH_FILE="pkgs/vendorhash.json"

APP_NAMES=$(jq -r 'keys[]' "$VENDOR_HASH_FILE")

for APP_NAME in $APP_NAMES; do

    HASH=$(grep -A 2 "error: hash mismatch" "$ERROR_LOG" | grep -A 2 "$APP_NAME" | grep "got:" | awk -F 'got: ' '{print $2}' | tr -d '[:space:]')

    if [ -n "$HASH" ]; then
        jq --arg app "$APP_NAME" --arg hash "$HASH" '.[$app] = $hash' "$VENDOR_HASH_FILE" > tmp.json && mv tmp.json "$VENDOR_HASH_FILE"

        echo "Updated $APP_NAME with vendorHash: $HASH"
    else
        echo "No incorrect vendorHash found for $APP_NAME in error log."
    fi
done