#!/bin/bash


# create MITM for each container
node mitm.js -n <container name> -i <container internal IP> -p <MITM listening port> --auto-access --auto-access-fixed <number of attempts before allowing access> --debug

# run MITM in the background
forever -l <full path of log file> start mitm.js <mitm options>