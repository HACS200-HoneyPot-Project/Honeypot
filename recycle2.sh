#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name ip"
    exit 1
fi

echo "Inside RECYCLE 2"

name=$1  # Given name
ip=$2    # Given external IP

# Get the container IP
container_ip=$(sudo lxc-info -n "$name" -iH)
if [[ -z $container_ip ]]; then
    echo "Error: Could not retrieve container IP. Ensure the container is running."
    exit 1
fi

echo "Container IP: $container_ip"

# Remove IP address and NAT rules
sudo ip addr delete "$ip"/16 + dev eth0
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$ip"


# Stop and destroy the container
sudo lxc-stop -n "$name"
sudo lxc-destroy -n "$name"
