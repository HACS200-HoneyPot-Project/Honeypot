#!/bin/bash

# Set up / redeploy the container with NAT rules

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 container_name external_ip"
    exit 1
fi

container_name="$1"
external_ip="$2"
count=0
port=65000
# port=$(shuf -i 50000-65000 -n 1)
port1=$(shuf -i 50000-53000 -n 1)
port2=$(shuf -i 53001-56000 -n 1)
port3=$(shuf -i 56001-59000 -n 1)
port4=$(shuf -i 59001-62000 -n 1)
port5=$(shuf -i 62001-65000 -n 1)

# sudo rm -r /run/lxc/lock/var
chmod u+x ~/recycle.sh

# sudo mkdir -p /run/lxc/lock
# sudo chmod 755 /run/lxc/lock

if [[ ! ( -d MITM_Logs ) ]]; then
    mkdir ~/MITM_Logs
    chmod 755 ~/MITM_Logs
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
banner_message=$(shuf -n 1 "$banner_file")
banner=""
log_file=""
if [ $(echo $banner_message | grep -c "great") -gt 0 ]; then
  banner="control"
  log_file=~/MITM_Logs/control_log/"$container_name.log"
elif [ $(echo $banner_message | grep -c "Welcome") -gt 0 ]; then
  banner="light"
  log_file=~/MITM_Logs/light_log/"$container_name.log"
elif [ $(echo $banner_message | grep -c "continuously") -gt 0 ]; then
  banner="medium"
  log_file=~/MITM_Logs/medium_log/"$container_name.log"
elif [ $(echo $banner_message | grep -c "Department") -gt 0 ]; then
  banner="high"
  log_file=~/MITM_Logs/high_log/"$container_name.log"
else
  echo "Error: Invalid banner message"
  exit
fi

chmod u+x $log_file

# SETUP SSH IN THE CONTAINER
sudo lxc-attach -n "$container_name" -- bash -c "
    apt-get update &&
    apt-get install -y openssh-server &&
    systemctl start ssh
"

# SET UP MITM + NAT RULES FOR MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

sudo chmod 777 /root/MITM/mitm.js

echo ""
echo "Finding log file"
echo "Currently listing all files in home directory: $(sudo ls -l ~)"
echo "Listing what is in MITM_Logs:"
sudo ls -l ~/MITM_Logs
sudo ls -l ~/MITM/mitm.js

# MITM COMMAND (FOREVER) TO RUN IN BACKGROUND
# MAKE PORT UNIQUE GENERATED BASED OFF EXTERNAL
if [[ $container_name == "container1" ]]; then
  sudo forever -a -l "$log_file" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port1" --auto-access --auto-access-fixed 1 --debug
  port="$port1"
elif [[ $container_name == "container2" ]]; then
  sudo forever -a -l "$log_file" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port2" --auto-access --auto-access-fixed 1 --debug
  port="$port2"
elif [[ $container_name == "container3" ]]; then
  sudo forever -a -l "$log_file" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port3" --auto-access --auto-access-fixed 1 --debug
  port="$port3"
elif [[ $container_name == "container4" ]]; then
  sudo forever -a -l "$log_file" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port4" --auto-access --auto-access-fixed 1 --debug
  port="$port4"
else
  sudo forever -a -l "$log_file" start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$port5" --auto-access --auto-access-fixed 1 --debug
  port="$port5"
fi

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
# banner_message=$(shuf -n 1 "$banner_file")

# Insert the banner into the container's /etc/motd
echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null

sudo lxc-attach -n "$container_name" -- bash -c "echo '$banner_message' > /etc/motd"

log_count=$(sudo cat "$log_file" | grep -c "Attacker closed connection") # Check number of logout events
login_count=$(sudo cat "$log_file" | grep -c "Attacker authenticated and is inside container") # Check number of login events

kick=false

attacker_left=false
attacker_inside=false

# While loop to check for logout keyword

monitor_logout_events() {
    while true; do
        new_count=$(sudo cat "$log_file" | grep -c "Attacker closed connection") # Check for the logout keyword
        new_login_count=$(sudo cat "$log_file" | grep -c "Attacker authenticated and is inside container") # Check for login keyword

        if [[ $new_count -gt $log_count ]] || $kick; then
            # ps aux
            attacker_left=true
            echo "Detected logout event. Executing recycle script."

            sudo iptables --delete INPUT --destination 10.0.3.1 --protocol tcp --dport "$port" --jump DROP
            sudo iptables --delete INPUT --source "$attacker_ip" --destination 10.0.3.1 --protocol tcp --dport "$port" --jump ACCEPT

            # Get the correct forever ID for the process associated with the container
            FOREVER_ID=$(sudo forever list | grep "${banner}_log" | awk '{print $2}' | cut -c 2)
            echo "Forever ID: $FOREVER_ID"
            echo "Forever List: $(sudo forever list)"
            echo "Forever List/Container: $(sudo forever list | grep "${banner}_log")"

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
         elif [[ $new_login_count -gt $login_count ]]; then # if an attacker is inside the container
            attacker_inside=true
            # ensure other attackers cannot connect
            sudo iptables --check INPUT --destination 10.0.3.1 --protocol tcp --dport "$port" --jump DROP
            if [[ $? -eq 1 ]]; then
              attacker_ip=$(sudo cat "$log_file" | grep "Attacker connected:" | awk 'END{print}' | cut -d " " -f 8)
              sudo iptables --insert INPUT --source "$attacker_ip" --destination 10.0.3.1 --protocol tcp --dport "$port" --jump ACCEPT
              sudo iptables --insert INPUT --destination 10.0.3.1 --protocol tcp --dport "$port" --jump DROP
            fi

            # check if inactive
            last_update_time=$(sudo tail -n 1 "$log_file" | cut -d " " -f -2)
            last_update_ms=$(date -d "$last_update_time" +'%s%3N')
            time_since=$(( $(date +'%s%3N') - "$last_update_ms" ))
            if [[ $time_since -gt 180000 ]]; then # if longer than 3 mins, kill the processes
                kick=true
            fi

            echo "last command: $time_since ms ago"

            # check total time in container
            login_time=$(sudo cat "$log_file" | grep "Attacker authenticated and is inside container" | awk 'END{print}' | cut -d " " -f -2)
            login_ms=$(date -d "$login_time" +'%s%3N')
            time_since=$(( $(date +'%s%3N') - "$login_ms"))
            if [[ $time_since -gt 900000 ]]; then
                kick=true
            fi

            echo "login: $time_since ms ago:"
         fi

        sleep 2 # Check every other second to avoid high CPU usage
    done
}


mitm_script() {
control_log=~/control_banner_timestamps.log
light_log=~/light_banner_timestamps.log
medium_log=~/medium_banner_timestamps.log
high_log=~/high_banner_timestamps.log
# Start monitoring
while true; do
    new_count=$(sudo cat "$log_file" | grep -c "Attacker closed connection") # Check for the logout keyword
    new_login_count=$(sudo cat "$log_file" | grep -c "Attacker authenticated and is inside container") # Check for login keyword

    if [[ $new_login_count -gt $login_count ]]; then

        echo "attacker inside, tracking time"
        # Record the start time
        start_time=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Identify the banner type by checking the .bashrc file - we should add a comment when we edit the banner file with the type of 
        # banner it is so this grepping is easier. or just grep a specific part of each banner, either way works
        if [ $(echo $banner_message | grep -c "great") -gt 0 ]; then
            time_log=$control_log
        elif [ $(echo $banner_message | grep -c "Welcome") -gt 0 ]; then
            time_log=$light_log
        elif [ $(echo $banner_message | grep -c "continuously") -gt 0 ]; then
            time_log=$medium_log
        elif [ $(echo $banner_message | grep -c "Department") -gt 0 ]; then
            time_log=$high_log
        else
            echo "Error: Invalid banner message"
            exit
        fi

        # Wait for the logout event to log the end time
        while true; do
            new_count=$(sudo cat "$log_file" | grep -c "Attacker closed connection")
            if [[ $new_count -gt $log_count ]]; then
                break
            else 
              sleep 0.1
            fi
        done

        # Record the end time
        end_time=$(date +"%Y-%m-%d %H:%M:%S")

        # Append session data (start and end times) to the corresponding log file
        echo "logging timestamps to file"
        echo "Login: $start_time, Logout: $end_time" >> $time_log
    fi
    sleep 0.1
done
}

mitm_script &

monitor_logout_events &
