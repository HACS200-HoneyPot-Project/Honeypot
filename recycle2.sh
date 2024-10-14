#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name ip"
    exit 1
fi

echo "Inside RECYCLE 2"

name=$1  # Given name
external_ip=$2    # Given external IP

# Get the container IP
container_ip=$(sudo lxc-info -n "$name" -iH)
if [[ -z $container_ip ]]; then
    echo "Error: Could not retrieve container IP. Ensure the container is running."
    exit 1
fi

echo "Container IP: $container_ip"

# Stop forever instance

f_index=$(sudo forever list | grep "$name" | cut -c 21)
if [[ -z $f_index ]]; then
    echo "No forever process found."
else
    forever stop "$f_index"
fi

# Remove IP address and NAT rules (not for MITM)
sudo ip addr delete "$external_ip"/16 brd + dev eth3

sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

# Stop and destroy the container
sudo lxc-stop -n "$name"
sudo lxc-destroy -n "$name"

# Reset the container
sudo lxc-create -n "$name" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n "$name"

# Get the internal IP of the container with detailed debugging
echo "Retrieving container IP for: $name"
sleep 7
# Try extracting the IP
container_ip=$(sudo lxc-info -n "$name" | grep "IP" | cut -d " " -f14)

echo "Container IP: '$container_ip'"  # Display what was extracted
# Check if IP was retrieved successfully
if [[ -z $container_ip ]]; then
    echo "Error: Could not retrieve container IP. Ensure the container is running."
    exit 1
fi
echo "Successfully retrieved Container IP: $container_ip"
# File containing banner messages
banner_file="banners.txt"

# SETUP SSH IN THE CONTAINER
sudo lxc-attach -n "$name" -- bash -c "
    apt-get update &&
    apt-get install -y openssh-server &&
    systemctl start ssh
"

# SET UP MITM + NAT RULES FOR MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
sudo forever -a -l ~/MITM_Logs/"${name}_log" start ~/MITM/mitm.js -n "$name" -i "$container_ip" -p 65000 --auto-access --auto-access-fixed 2 --debug

sleep 5

# NAT RULES FOR MITM
sudo ip addr add "$external_ip"/16 brd + dev eth3
sudo iptables --table nat --append PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --append POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"


# Put the banner in the container
sudo lxc-attach -n "$name" -- bash -c "   
    # Clear banner files
    echo '' > /etc/issue &&
    echo '' > /etc/issue.net &&
    echo '' > /etc/motd &&
    rm -f /etc/update-motd.d/*
"

# Randomize the banner message
banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$name"/rootfs/etc/motd > /dev/null