#!/bin/bash

# most of these are notes - but the bottom parts is where you should look for actual code and stuff

# TO DO
# set up / redeploy the container with NAT rules
# look at week 11, HW8 & W7 - scheduling from last semester for NAT rules
# hw8 also has shuf command for randomizing banners
# take a container name & ip as the parameters
# create a new container with that name and ip for that 
# set up nat rules, postrouting when it shuts down
# randomize banners
# nat rules prerouting to strart it up again


# TO DESTROY THE CONTAINER
# PARAMETERS ARE THE CONTAINERS NAME AND THE IP ASSOCIATED
# CONTAINER IP CAN GOTTEN FROM THIS SCRIPT I THINK

if [[ $# != 2 ]]; then
	echo "usage: script container_name ip"
	exit 1
fi

name = $1 # given name
ip = $2 # given external ip
container_ip = `sudo lxc-info "$1" -iH` # the actual container ip

sudo ip addr delete "$ip"/16 brd + dev eth0 [MIGHT BE eth3]
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 -- destination "$ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$ip"

sudo lxc-stop -n "$name"
sudo lxc-destroy -n "$name"