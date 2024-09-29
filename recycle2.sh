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


###### MY NOTES 
pot_name = $1
pot_ip = $2
banner_message=$(shuf -n 1 "banners.txt") # to randomly get a banner message

my_ip="172.30.250.127" - idk 

sudo lxc-create -n "$pot_name" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n "$pot_name"

sudo ip addr add "$my_ip"/16 brd + dev eth0
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 -- destination "$my_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$my_ip"


sudo ip addr delete "$my_ip"/16 brd + dev eth0
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 -- destination "$my_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$my_ip"


sudo lxc-stop -n "$some_name"
sudo lxc-destroy -n "$some_name"


****************************************************************************
TO DESTROY THE CONTAINER
PARAMETERS ARE THE CONTAINERS NAME AND THE IP ASSOCIATED
CONTAINER IP CAN GOTTEN FROM THIS SCRIPT I THINK

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