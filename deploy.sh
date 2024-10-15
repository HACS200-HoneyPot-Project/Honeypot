#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

container_name="$1"
external_ip="$2"
count=0
port=$(shuf -i 50000-65000 -n 1)

# sudo rm -r /run/lxc/lock/var
chmod u+x ~/recycle.sh

# sudo mkdir -p /run/lxc/lock
# sudo chmod 755 /run/lxc/lock

if [[ ! ( -d MITM_Logs ) ]]; then
    mkdir ~/MITM_Logs
    chmod 755 ~/MITM_Logs
fi

log_file="~/MITM_Logs/${container_name}_log"

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

sleep 7

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
    systemctl start ssh
"

# SET UP MITM + NAT RULES FOR MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

sudo chmod 777 /root/MITM/mitm.js

echo 
echo "Finding log file"
echo "Currently listing all files in home directory: $(sudo ls -l ~)"
echo "Listing what is in MITM_Logs:"
sudo ls -l ~/MITM_Logs
sudo ls -l ~/MITM/mitm.js

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
sudo forever -a -l ~/MITM_Logs/"${container_name}_log" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port" --auto-access --auto-access-fixed 1 --debug

sleep 5

# NAT RULES FOR MITM
sudo ip addr add "$external_ip"/16 brd + dev eth0
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $external_ip --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:"$port"

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
    mkdir -p ~/student_data
"

sudo cp ~/honey.csv /var/lib/lxc/"$container_name"/rootfs/home/student_data

#command to move honey into the container directory
# Push the honey.csv file to the container
sudo lxc file push ~/honey.csv "$container_name"/home/student_data/

# Change the file ownership to root and allow all users to access it
sudo lxc-attach -n "$container_name" -- bash -c "chown root:root ~/student_data/records && chmod 777 ~/student_data/records"

# Randomize the banner message
banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null

sudo lxc-attach -n "$container_name" -- bash -c "echo '$banner_message' > /etc/motd"

log_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check number of logout events

# While loop to check for logout keyword
monitor_logout_events() {
    while true; do
        new_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check for the logout keyword
        login_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker authenticated and is inside container") # Check for login keyword

        if [[ $new_count -gt $log_count ]]; then
            # ps aux
            echo "Detected logout event. Executing recycle script."

            # Get the correct forever ID for the process associated with the container
            FOREVER_ID=$(sudo forever list | grep "${container_name}_log" | awk '{print $2}' | cut -c 2)
            echo "Forever ID: $FOREVER_ID"
            echo "Forever List: $(sudo forever list)"
            echo "Forever List/Container: $(sudo forever list | grep "${container_name}_log")"

            # Stop the process using the forever ID
            if [[ ! -z "$FOREVER_ID" ]]; then
                echo "Stopping forever process with ID: $FOREVER_ID"
                sudo forever stop "$FOREVER_ID"
            else
                echo "No matching forever process found for $container_name"
            fi
            echo
            echo "Starting recycle script"
            ./recycle.sh "$container_name" "$external_ip" "$container_ip" "$port"
            break
         elif [[ $login_count -gt $log_count ]]; then # if an attacker is inside the container 
              # check if inactive
            last_update_time=$(sudo tail -n 1 ~/MITM_Logs/"${container_name}_log" | cut -d " " -f -2)
            last_update_ms=$(date -d "$last_update_time" +'%s%3N')
            time_since=$(( $(date +'%s%3N') - "$last_update_ms" ))
            if [[ $time_since -gt 180000 ]]; then # if longer than 3 mins, kill the processes
                new_count=$(($new_count + 1))
            fi

            # check total time in container
            login_time=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep "Attacker authenticated and is inside container" | awk 'END{print}' | cut -d " " -f -2)
            login_ms=$(date -d "$login_time" +'%s%3N')
            time_since=$(( $(date +'%s%3N') - "$login_ms"))
            if [[ $time_since -gt 900000 ]]; then
                new_count=$(($new_count + 1))
            fi
         fi

        sleep 2 # Check every other second to avoid high CPU usage
    done
}

monitor_logout_events