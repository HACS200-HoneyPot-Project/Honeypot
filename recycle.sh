#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 container_name external_ip container_ip" "port"
    exit 1
fi

container_name="$1"
external_ip="$2"
container_ip="$3"
port="$4"

sleep 5

echo "redeploying $1..."

sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"

sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $external_ip --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:"$port"



sudo ./deploy.sh "$1" "$2"