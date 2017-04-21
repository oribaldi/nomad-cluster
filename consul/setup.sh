#!/bin/bash

usage() {
    echo ""
    echo "${0} <hostname> <encrypt> <private ip 1> <private ip 2> <private ip 3> <private ip 4>"
    echo ""
    echo "Arguments"
    echo "Hostname     - [REQUIRED] The hostname you want to provide for your consul agent."
    echo "Encrypt      - [REQUIRED] This is acquired by running consul keygen."
    echo "Private IP 1 - [REQUIRED] The private IP address of your consul agent."
    echo "Private IP 2 - [REQUIRED] The private IP address of another server in the cluster."
    echo "Private IP 3 - [REQUIRED] The private IP address of another server."
    echo "Private IP 4 - [OPTIONAL] The private IP address of another server. Only required if this consul agent is a client."
    echo ""

    return
}

# Check to make sure the correct number of arguments is passed
if [ "$#" -lt 5 ]; 
then
    usage
    exit
fi

HOSTNAME=$1
ENCRYPT=$2
PRIVATE_IP1=$3
PRIVATE_IP2=$4
PRIVATE_IP3=$5

sed -i -- "s/__NODE_NAME__/$HOSTNAME/g" /vagrant/consul/config.json
sed -i -- "s/__ENCRYPTION__/$ENCRYPT/g" /vagrant/consul/config.json
sed -i -- "s/__PRIVATE_IP1__/$PRIVATE_IP1/g" /vagrant/consul/config.json
sed -i -- "s/__PRIVATE_IP2__/$PRIVATE_IP2/g" /vagrant/consul/config.json
sed -i -- "s/__PRIVATE_IP3__/$PRIVATE_IP3/g" /vagrant/consul/config.json

if [ "$#" -eq 6 ];
then
    PRIVATE_IP4=$6
    sed -i -- "s/__PRIVATE_IP0__/$PRIVATE_IP4/g" /vagrant/consul/config.json
fi
