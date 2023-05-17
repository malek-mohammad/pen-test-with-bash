#!/bin/bash

# We check for executables
if ! command -v arping &> /dev/null
then
    echo "arping is not found! Please install it first"
    exit 1
elif ! command -v nmap &> /dev/null
then
    echo "nmap is not found! Please install it first"
    exit 1
fi

# We check if the script has root privileges
if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root"
  exit 1
fi

# We prompt user for IP range
read -p "Enter IP range (e.g. 192.168.1.1-192.168.1.10): " ip_range

# We validate the user's input
regex='^((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)-((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'

if ! [[ $ip_range =~ $regex ]]; then
    echo "Invalid IP range"
    exit 1
fi

# We split IP range into start and end IP addresses
start_ip=$(echo $ip_range | cut -d '-' -f 1)
end_ip=$(echo $ip_range | cut -d '-' -f 2)
ip_3_octets=$(echo $start_ip | cut -d '.' -f1-3)
range_start=$(echo $start_ip | cut -d '.' -f 4)
range_end=$(echo $end_ip | cut -d '.' -f 4)

# We empty the hosts temp file
> hosts.txt

# We loop through all IP addresses in range and scan each one
for ((i=$range_start;i<=$range_end;i++)); do
  ip="$ip_3_octets.$i"
  if [ "$ip" == "$end_ip" ]; then
    break
  fi
  
  echo "arping: $ip"
  arping -c 3 $ip | grep "reply from" | cut -d" " -f4 | sort -u >> hosts.txt
  
done

# We check the scan result
if [[ ! -s "hosts.txt" ]]; then
    echo "Non of the IPs in range is up"
    exit 0
fi

echo "Active hosts:"
cat hosts.txt

# We loop through each host and perform port scanning, banner grabbing, and vulnerability scanning
while read host; do
    echo "Scanning $host..."
    
    # Port scanning with nmap
    echo "Performing port scanning..."
    nmap -sS -T4 -Pn -p- $host > ports.txt
    
    if [[ -s "ports.txt" ]]; then
    	echo "Open ports:"
    	cat ports.txt | grep -E '^[0-9]+/' | cut -d"/" -f1 | tr '\n' ',' | sed 's/,$//'
    else
	echo "No ports found open"
    fi
    
    echo ""

    # Vulnerability scanning with nmap
    echo "Performing vulnerability scanning with nmap..."
    nmap -sV --script vuln $host
    
    echo ""
done < hosts.txt

