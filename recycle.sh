#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

sudo ~/deploy.sh "$container_name" "$external_ip"

echo "redeploying $container_name..."