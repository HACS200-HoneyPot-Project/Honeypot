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

# We need to still figure out how the bash rc file works to display the message
# Insert the banner into the container's /etc/motd (Message of the Day)
# This is how chat gpt said to display the banner in the container below, not final 
# echo "$banner_message" | sudo tee /var/lib/lxc/"$container_name"/rootfs/etc/motd > /dev/null