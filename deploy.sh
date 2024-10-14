#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

container_name=$1
external_ip=$2

sudo rm -r /run/lxc/lock/var
chmod +x ~/recycle.sh

if [[ ! -d MITM_Logs ]]; then
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

# Get the internal IP of the container with detailed debugging
echo "Retrieving container IP for: $container_name"
# Wait until the container is running
for i in {1..10}; do
    if sudo lxc-info -n "$container_name" | grep -q "RUNNING"; then
        break
    fi
    sleep 2
done

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
    systemctl start ssh
"

# SET UP MITM + NAT RULES FOR MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
sudo forever -a -l ~/MITM_Logs/"${container_name}_log" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p 65000 --auto-access --auto-access-fixed 1 --debug

sleep 5

count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check number of logout events

# NAT RULES FOR MITM
sudo ip addr add "$external_ip"/16 brd + dev eth3
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $external_ip --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:65000

# Put the banner in the container
sudo lxc-attach -n "$container_name" -- bash -c "   
    # Clear banner files
    echo '' > /etc/issue &&
    echo '' > /etc/issue.net &&
    echo '' > /etc/motd &&
    rm -f /etc/update-motd.d/*
"

# Make a directory and file inside the container that contains the honey 
sudo lxc-attach -n "$container_name" -- bash -c "   
    mkdir -p /home/student_data 
    touch /home/student_data/records
"

#command to move honey into the container directory 
# Push the honey.csv file to the container
sudo lxc file push ~/honey.csv "$container_name"/home/student_data/records

# Change the file ownership to root and allow all users to access it
sudo lxc-attach -n "$container_name" -- bash -c "chown root:root /home/student_data/records && chmod 777 /home/student_data/records"

# Randomize the banner message
banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null

sudo lxc-attach -n "$container_name" -- bash -c "echo '$banner_message' > /etc/motd"

# While loop to check for logout keyword
monitor_logout_events() {
    while true; do
        new_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check for the logout keyword

        if [[ $new_count -gt $count ]]; then
            echo "Detected logout event. Executing recycle script."
            ~/recycle.sh "$container_name" "$external_ip"
        else
            echo "No logout events detected."
        fi

        sleep 1 # Check every second to avoid high CPU usage
    done
}

monitor_logout_events &

