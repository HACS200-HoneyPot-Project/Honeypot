#!/bin/bash

int i=1;
ip1="[REPLACE WITH IP]"
ip2="[REPLACE WITH IP]"
ip3="[REPLACE WITH IP]"
ip4="[REPLACE WITH IP]"

# port redirection
sudo sysctl -w net.ip4.conf.all.route_localnet=1

# install for background
npm install -g forever

~/firewall_rules.sh

dos2unix ~/deploy.sh
dos2unix ~/firewall_rules.sh
dos2unix ~/recycle.sh
dos2unix ~/mitm.sh

#call deploy.sh script for each container
for i in {1..5}; do
    ~/deploy.sh "container$i" "ip$i"
done