#!/bin/bash

TEMP_FILE=$(mktemp)

nix flake update
nix build --no-link .#caddyWithCloudflare 2> >(grep got | sed 's/ *got: *\(.*\) */"\1"/' > "$TEMP_FILE")

if [ "$(cat "$TEMP_FILE")" != "" ]; then
    cat "$TEMP_FILE" > hash.nix 
fi
