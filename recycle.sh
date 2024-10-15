#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

sleep 5

echo "redeploying $1..."

sudo ./deploy.sh "$1" "$2"