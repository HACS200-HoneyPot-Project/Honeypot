#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

container_name=$1
external_ip=$2

if [[ ! ( -d MITM_Logs ) ]]; then
    mkdir MITM_Logs
fi

# CREATE/STOP CONTAINER
count=$(sudo lxc-ls | grep -c "$container_name")
if [[ $count -ne 0 ]]
then
    # IF IT DOES EXIST, STOP IT AND DESTROY IT
    sudo lxc-stop -n "$container_name"
    sudo lxc-destroy -n "$container_name"
fi

# IF IT DOESNT EXIST, CREATE IT
sudo lxc-create -n "$container_name" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n "$container_name"

sudo ip addr add "$external_ip"/16 brd + dev eth3

# Get the internal IP of the container with detailed debugging
echo "Retrieving container IP for: $container_name"
sleep 7
# Try extracting the IP
container_ip=$(sudo lxc-info -n "$container_name" | grep "IP" | cut -d " " -f14)

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
sudo lxc-attach -n "$container_name" -- bash -c "
    apt-get update &&
    apt-get install -y openssh-server &&
    systemctl start ssh &&
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config &&
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config &&
    echo 'root:pass' | chpasswd &&  # Set root password to 'pass'
    systemctl restart ssh
"

# SET UP MITM + NAT RULES FOR MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
sudo forever -a -l ~/MITM_Logs/"${container_name}_log" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p 65000 --auto-access --auto-access-fixed 2 --debug

sleep 5

# NAT RULES FOR MITM
sudo ip addr add "$external_ip"/16 brd + dev eth3
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:65000



# Setup SSH in the container
sudo lxc-attach -n "$container_name" -- bash -c "
    echo 'root:pass' | chpasswd &&  # Set root password to 'pass'
    
    # Clear banner files
    echo '' > /etc/issue &&
    echo '' > /etc/issue.net &&
    echo '' > /etc/motd &&
    rm -f /etc/update-motd.d/*
"

# Randomize the banner message
banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null

# While loop to check for logout keyword
# while true; do
#     count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "logout") # Check for the logout keyword

#     if [[ $count -gt 0 ]]; then
#         echo "Detected logout event. Executing recycle script."
#         ~/recycle2.sh "$container_name" "$external_ip"
#     else
#         echo "No logout events detected."
#     fi

#     sleep 1 # Check every second to avoid high CPU usage
# done


# We need to still figure out how the bash rc file works to display the message
# Insert the banner into the container's /etc/motd (Message of the Day)
# This is how chat gpt said to display the banner in the container below, not final 
# echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null
