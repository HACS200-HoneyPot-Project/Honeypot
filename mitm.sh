#!/bin/bash

# Track MITM Logs, and identify when attacker logs in to start timer. 
    # Figure out how to get start and end time accurately
    # Figure out how to identify which banner is being run on the container
        # Cat the bashrc file, and grep for the unique words of each banner message, and then based on that append the data to a file

# Container name is passed in as the first argument
container_name=$1

# Path to the MITM log file for this container - where is the mitm log stored?
mitm_log=~"/${container_name}_log"

# Path to the container's .bashrc file to identify the banner
bashrc_path="/home/user/.bashrc"

# Paths to log files for each banner type - need to decide where we want to store the logs
# control_log="/path/to/logs/control_banner_data.log"
# light_log="/path/to/logs/light_banner_data.log"
# medium_log="/path/to/logs/medium_banner_data.log"
# high_log="/path/to/logs/high_banner_data.log"
control_log=~"/control_banner_timestamps.log"
light_log=~"/light_banner_timestamps.log"
medium_log=~"/medium_banner_timestamps.log"
high_log=~"/high_banner_timestamps.log"

# Start monitoring
while true; do
    # Monitor the MITM log for login events
    if tail -n 1 $mitm_log | grep -q "Attacker is authenticated and inside the container"; then
        # Record the start time
        start_time=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Identify the banner type by checking the .bashrc file - we should add a comment when we edit the banner file with the type of 
        # banner it is so this grepping is easier. or just grep a specific part of each banner, either way works
        if grep -q "Control Banner" $bashrc_path; then
            log_file=$control_log
        elif grep -q "Light Banner" $bashrc_path; then
            log_file=$light_log
        elif grep -q "Medium Banner" $bashrc_path; thenl
            log_file=$medium_log
        else
            log_file=$high_log
        fi

        # Wait for the logout event to log the end time
        while ! tail -n 1 $mitm_log | grep -q "Logout"; do # idk if logout is accurate need to test mitm logs and see
            sleep 0.1
        done

        # Record the end time
        end_time=$(date +"%Y-%m-%d %H:%M:%S")

        # Append session data (start and end times) to the corresponding log file
        echo "Login: $start_time, Logout: $end_time" >> $log_file
    fi
    sleep 0.1
done