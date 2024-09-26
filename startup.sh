#!/bin/bash


# create MITM for each container
node mitm.js -n <container name> -i <container internal IP> -p <MITM listening port> --auto-access --auto-access-fixed <number of attempts before allowing access> --debug

# run MITM in the background
sudo forever -l ~/$1_log start ~/MITM/mitm.js -n $1 -i

# When we start everything up, we set up the tracking of mitm to see when attacker logs out.
# Signaling the shutting off/recycling of script
    # While loop to have script check every millisecond
        while true; do {
            int count = tail -f /path-for-mitm-log | grep -c "logout" #figure out the keyword for logging out

            if (count > 0) {
                # call recycling script
            }

            sleep 0.001 # - every millisecond (should we go smaller? how fast are commands run?)
        }
    # Using grep - if the last line of of the log says that there was a log out
        # Call script to shut down and recycle the container