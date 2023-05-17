#!/bin/bash

# We Check if ipcalc is installed
if ! command -v ipcalc &> /dev/null; then
    echo "ipcalc is not installed. Please install it and try again."
    exit 1
fi

# We Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "nmap is not installed. Please install it and try again."
    exit 1
fi

# We check if the script has root privileges
if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root"
  exit 1
fi

# Function gets number of IPs inside a CIDR block
function get_total_ips() {
    local cidr=$1
    local mask=$(echo "$cidr" | cut -d '/' -f 2)
    local total_ips=$((2**(32-mask)))
    echo "$total_ips"
}

# Function that validates the user input of IPs
function is_valid_ip() {
    local ip=$1
    local regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    if [[ $ip =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Function that validates the user input of ports
function is_valid_ports() {
    local ports=$1
    local regex='^([0-9]{1,5}(,[0-9]{1,5})*)?$'
    if [[ $ports =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Function converts user input to CIDR block
function convert_range_to_cidr() {
    local ip_range=$1
    IFS='-' read -ra ADDR <<< "$ip_range"
    local start_ip="${ADDR[0]}"
    local end_ip="${ADDR[1]}"
    local cidr_ranges=$(ipcalc -rn "$start_ip" "$end_ip" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}')
    echo "$cidr_ranges"
}

# We get the IP range from the user
while true; do
    echo "Enter the IP range to scan (e.g., 192.168.100.1-192.168.100.5):"
    read ip_range

    IFS='-' read -ra ADDR <<< "$ip_range"
    if [ ${#ADDR[@]} -eq 2 ] && is_valid_ip "${ADDR[0]}" && is_valid_ip "${ADDR[1]}"; then
        break
    else
        echo "Invalid IP range format. Please try again."
    fi
done

cidr_ranges=$(convert_range_to_cidr "$ip_range")

# We get the ports from the user
while true; do
    echo "Enter the specific ports to scan (e.g., 22,80,443) or leave blank for all ports:"
    read ports

    if is_valid_ports "$ports"; then
        break
    else
        echo "Invalid ports format. Please try again."
    fi
done

if [ -z "$ports" ]; then
    ports_arg=""
else
    ports_arg="-p $ports"
fi

# We start scanning each IP in all CIDR ranges
for cidr_range in $cidr_ranges; do

    echo ""
    echo "Scanning CIDR range: $cidr_range"
    
    ping_scan_cmd="nmap -sn -PE $cidr_range"
    echo "Running initial ping scan: $ping_scan_cmd"
    ping_scan_output=$(eval "$ping_scan_cmd")
    echo "$ping_scan_output"

    discovered_hosts=$(echo "$ping_scan_output" | grep -c "Host is up")
    echo "Discovered $discovered_hosts hosts."

    total_ips_in_cidr=$(get_total_ips "$cidr_range")

    if [ $discovered_hosts -eq $total_ips_in_cidr ]; then
        echo "All IP addresses in the CIDR range have been discovered. Skipping the rest of the scan types."
        continue
    fi
 
    scan_types=("ARP (local network only)" "TCP SYN (half-open) scan" "TCP ACK scan" "UDP scan" "SCTP INIT scan")
   
    discovered_hosts=$(echo "$ping_scan_output" | grep -c "Host is up")
    echo "Discovered $discovered_hosts hosts."

    scan_types=("ARP (local network only)" "TCP SYN (half-open) scan" "TCP ACK scan" "UDP scan" "SCTP INIT scan")
    scan_commands=("nmap -sn -PR" "nmap -sS $ports_arg" "nmap -sA $ports_arg" "nmap -sU $ports_arg" "nmap -sY $ports_arg")

    for i in "${!scan_types[@]}"; do
	echo ""
        echo "Trying ${scan_types[$i]}:"
        nmap_cmd="${scan_commands[$i]} $cidr_range"
        echo "Running Nmap command: $nmap_cmd"
        nmap_output=$(eval "$nmap_cmd")
        echo "$nmap_output"

        discovered_hosts=$(echo "$nmap_output" | grep -c "Host is up")
        echo "Total hosts discovered: $discovered_hosts"
    done

done

echo "Finished trying all scan types."

