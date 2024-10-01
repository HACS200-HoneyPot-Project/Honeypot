# set up / redeploy the container with NAT rules

# look at week 11, HW8 & W7 - scheduling from last semester for NAT rules
# hw8 also has shuf command for randomizing banners

# take a container name & ip as the parameters
# create a new container with that name and ip for that 
# set up nat rules, postrouting when it shuts down

# randomize banners

# nat rules prerouting to strart it up again

if [[ $# != 2 ]]; then
	echo "Usage: $0 container_name external_ip"
	exit 1
fi

container_name=$1
external_ip=$2
container_ip=$(sudo lxc-info -n "$container_name" -iH)
banner_file="banners.txt"

sudo lxc-create -n "$1" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n "$1"

sudo ip addr add "$1"/16 brd + dev eth0
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 -- destination "$2" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$2"

banner_message=$(shuf -n 1 "$banner_file")

# create MITM for each container and run in background
sudo forever -l ~/"$container_name"_log start ~/MITM/mitm.js -n "$container_name" -i "$container_ip" -p 6459 --auto-access --auto-access-fixed 2 --debug

# When we start everything up, we set up the tracking of mitm to see when attacker logs out.
# Signaling the shutting off/recycling of script
# While loop to have script check every millisecond
while true; do {
    int count = tail -f ~/"$container_name"_log | grep -c "logout" #figure out the keyword for logging out

    if (count > 0) {
        ~/recycle.sh "$container_name" "$container_ip"
    }

    sleep 0.001 # - every millisecond (should we go smaller? how fast are commands run?)
}

# We need to still figure out how the bash rc file works to display the message
# Insert the banner into the container's /etc/motd (Message of the Day)
# This is how chat gpt said to display the banner in the container below, not final 
# echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null