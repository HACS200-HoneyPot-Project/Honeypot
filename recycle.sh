#!/bin/bash

# takes 1. container name 2. container ip
if [ $# -ne 2 ]
then
    echo "Please enter 1. container name and 2. container ip"
    exit 1
fi

ctr_name=$1
ctr_ip=$2

# set up / redeploy the container with NAT rules
    # maybe we have some snapshot or something to have the saved configuration

# shut down the container when attacker leaves
    # find mitm logs
    # grep out log out

# randomize banner message

rand=$(( 1 + $RANDOM % 4 )) # use this number to edit the banner message (from banners.txt?)

# redeploy (NAT rules)

# data collection - time & commands