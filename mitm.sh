#!/bin/bash

# Signaling the shutting off/recycling of script
    # While loop to have script check every millisecond
        while true; do {
            int count = tail -f /path-for-mitm-log | grep -c "logout" #figure out the keyword for logging out

            if (count > 0) {
                
            }

            sleep 0.001 - every millisecond (should we go smaller? how fast are commands run?)
        }
    # Using grep - if the last line of of the log says that there was a log out
        # Call script to shut down and recycle the container



    
