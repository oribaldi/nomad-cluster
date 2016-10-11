#!/bin/bash

usage() {
    echo ""
    echo "${0} <private ip> <config file path>"
    echo ""
    echo "Arguments"
    echo "Private IP       - [REQUIRED] The private IP address of the Nomad agent."
    echo "Config File Path - [REQUIRED] The path of the config file to setup."
    echo ""

    return
}

# Check to make sure the correct number of arguments is passed
if [ "$#" -ne 2 ]; 
then
    usage
    exit
fi

PRIVATE_IP=$1

sed -i -- "s/__IP_ADDRESS__/$PRIVATE_IP/g" $2
