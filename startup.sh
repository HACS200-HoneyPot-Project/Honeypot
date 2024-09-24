#!/bin/bash


# create MITM for each container
node mitm.js -n <container name> -i <container internal IP> -p <MITM listening port> --auto-access --auto-access-fixed <number of attempts before allowing access> --debug

# run MITM in the background
sudo forever -l ~/$1_log start ~/MITM/mitm.js -n $1 -i