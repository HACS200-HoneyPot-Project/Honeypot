#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

container_name="$1"
external_ip="$2"
count=0
port=$(shuf -n 1 50000-65000)

# sudo rm -r /run/lxc/lock/var
chmod u+x ~/recycle.sh

sudo mkdir -p /run/lxc/lock
sudo chmod 755 /run/lxc/lock

if [ (! -d ~/MITM_Logs) ]; then
  mkdir ~/MITM_Logs
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

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
sudo forever -a -l ~/MITM_Logs/"${container_name}_log" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port" --auto-access --auto-access-fixed 1 --debug

sleep 5

# NAT RULES FOR MITM
sudo ip addr add "$external_ip"/16 brd + dev eth0
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

<<<<<<< HEAD
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $external_ip --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:"$port"
=======
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:65000
>>>>>>> 322d489aaededf27822e82f7655e141a8f62a515

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
sudo lxc-attach -n "$container_name" -- bash -c "chown root:root /home/student_data/records && chmod 777 /home/student_data/records"

# Randomize the banner message
banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null

sudo lxc-attach -n "$container_name" -- bash -c "echo '$banner_message' > /etc/motd"

<<<<<<< HEAD
log_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check number of logout events
=======
logout_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check number of logout events
>>>>>>> 322d489aaededf27822e82f7655e141a8f62a515

# While loop to check for logout keyword
monitor_logout_events() {
    while true; do
        new_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker closed connection") # Check for the logout keyword
        login_count=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep -c "Attacker authenticated and is inside container") # Check for login keyword

<<<<<<< HEAD
        if [[ $new_count -gt $log_count ]]; then
=======
        if [[ $new_count -gt $logout_count ]]; then
>>>>>>> 322d489aaededf27822e82f7655e141a8f62a515
            # ps aux
            echo "Detected logout event. Executing recycle script."
            # PID=$(pgrep -f "${container_name}_log")
            INDEX=$(sudo forever list | grep "~/MITM_Logs/container_log" | awk '{print $1}' | sed 's/\[//g' | sed 's/\]//g')
            sudo forever stop --index $INDEX

<<<<<<< HEAD
            sudo forever stop --script ~/MITM/mitm.js --args "-n container -i "$container_ip" -p "$port" --auto-access --auto-access-fixed 1 --debug" --logfile ~/MITM_Logs/"${container_name}_log"
=======
            sudo forever stop --script ~/MITM/mitm.js --args "-n container -i "$container_ip" -p 65000 --auto-access --auto-access-fixed 1 --debug" --logfile ~/MITM_Logs/"${container_name}_log"
>>>>>>> 322d489aaededf27822e82f7655e141a8f62a515
            sudo ~/recycle.sh "$container_name" "$external_ip"

            # Get the correct forever ID for the process associated with the container
            FOREVER_ID=$(forever list | grep "${container_name}_log" | awk '{print $3}')

            # Stop the process using the forever ID
            if [[ ! -z "$FOREVER_ID" ]]; then
                echo "Stopping forever process with ID: $FOREVER_ID"
                sudo forever stop "$FOREVER_ID"
            else
                echo "No matching forever process found for $container_name"
            fi
            kill $BGPID
<<<<<<< HEAD
        # else
            # echo "No logout events detected."
=======
        elif [[ $login_count -gt $logout_count ]]; then # if an attacker is inside the container 
            kick=0
            # check if inactive
            last_update_time=$(sudo cat ~/MITM_Logs/"${container_name}_log" | awk 'END{print}' | cut -d " " -f -2)
            last_update_ms=$(date -d $last_update_time +'%s%3N')
            time_since=$(( $(date +'%s%3N') - $last_update_ms))
            if [[ $time_since -gt 180000 ]]; then # if longer than 10 mins, kill the processes
                kick=1
            fi

            # check total time in container
            login_time=$(sudo cat ~/MITM_Logs/"${container_name}_log" | grep "Attacker authenticated and is inside container" | awk 'END{print}' | cut -d " " -f -2)
            login_ms=$(date -d $login_time +'%s%3N')
            time_since=$(( $(date +'%s%3N') - $login_ms))
            if [[ $time_since -gt 900000 ]]; then
                kick=1
            fi

            if [[ $kick -eq 1 ]]; then
                INDEX=$(sudo forever list | grep "~/MITM_Logs/container_log" | awk '{print $1}' | sed 's/\[//g' | sed 's/\]//g')
                sudo forever stop --index $INDEX

                sudo forever stop --script ~/MITM/mitm.js --args "-n container -i "$container_ip" -p 65000 --auto-access --auto-access-fixed 1 --debug" --logfile ~/MITM_Logs/"${container_name}_log"
                sudo ~/recycle.sh "$container_name" "$external_ip"

                # Get the correct forever ID for the process associated with the container
                FOREVER_ID=$(forever list | grep "${container_name}_log" | awk '{print $3}')

                # Stop the process using the forever ID
                if [[ ! -z "$FOREVER_ID" ]]; then
                    echo "Stopping forever process with ID: $FOREVER_ID"
                    sudo forever stop "$FOREVER_ID"
                else
                    echo "No matching forever process found for $container_name"
                fi
                kill $BGPID
            fi
>>>>>>> 322d489aaededf27822e82f7655e141a8f62a515
        fi

        sleep 2 # Check every other second to avoid high CPU usage
    done
}

monitor_logout_events &
BGPID=$!