#!/bin/bash

if [[ $# != 1 ]]; then
        echo "Usage: $0 ip_address"
        exit 1
fi

# take in an ip address

ping -c5 $1 | grep 'time=' | cut -d' ' -f7 | cut -d'=' -f2 > $1_file
awk '{print $1 / 2}' $1_file > temp && mv temp $1_file
awk '{ total += $1; count += 1 } END { print total / count }' $1_file> temp && mv temp $1_file

average=$(cat $1_file)

echo $1, $average >> file.txt # file.txt will store all the duration times or something like that
# writes the ip address and average time into file

rm $1_file 
