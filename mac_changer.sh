#!/bin/bash

# function to change the MAC address
function change_mac() {

  # We display list of network interfaces
  echo "Available network interfaces:"
  ip link show | awk -F': ' '/^[0-9]+:/{print $2}'

  echo ""

  echo -n "Enter the network interface to change the MAC address for (e.g. eth0): "
  read -r interface

  # We check if the backup file exists and prompt the user to restore old MAC address
  if [[ -f "/etc/macchanger/$interface" ]]; then
    echo "A backup file for $interface was found."
    echo -n "Do you want to restore the original MAC address for $interface? (y/n): "
    read -r restore_mac

    if [[ "$restore_mac" == "y" ]]; then
      original_mac=$(cat "/etc/macchanger/$interface")
      echo "Restoring original MAC address $original_mac for $interface"
      sudo ip link set dev "$interface" address "$original_mac"
      sudo rm "/etc/macchanger/$interface"
      echo "Done."
      exit 0
    fi
  fi

  # We get user input to determine which method to use for MAC address retrieval
  echo -n "Choose a method for changing the MAC address for $interface:
  1) Generate a random MAC address
  2) Enter a new MAC address
  3) Get the MAC address for a specific IP address and set it
  Choose an option (1/2/3): "
  read -r method

  # We change the MAC address based on the selected method
  if [[ "$method" == "1" ]]; then
    new_mac=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  elif [[ "$method" == "2" ]]; then
    echo -n "Enter the new MAC address (format: xx:xx:xx:xx:xx:xx): "
    read -r new_mac
  elif [[ "$method" == "3" ]]; then
    echo -n "Enter the IP address to retrieve the MAC address for: "
    read -r ip_address
    arping -c 1 "$ip_address" | grep "reply from" | awk '{print $5}'
    new_mac=$(arping -c 1 "$ip_address" | grep "reply from" | awk '{print $5}' | tr -d '[]')
  else
    echo "Invalid option. Exiting."
    exit 1
  fi

  # We backup the original MAC address before changing it
  current_mac=$(ip link show "$interface" | awk '/ether/ {print $2}')
  echo "Backing up current MAC address $current_mac for $interface"
  [[ -d "/etc/macchanger"  ]] || sudo mkdir "/etc/macchanger"
  [[ -f "/etc/macchanger/$interface" ]] || sudo touch "/etc/macchanger/$interface"
  sudo sh -c "echo '$current_mac' > /etc/macchanger/$interface"

  # We change the MAC address
  echo "Changing MAC address for $interface to $new_mac"
  sudo ip link set dev "$interface" address "$new_mac"

  echo "Done."
}

# Check for executables
if ! command -v openssl &> /dev/null
then
    echo "openssl is not found! Please install it first"
    exit 1
fi

if ! command -v arping &> /dev/null
then
    echo "arping is not found! Please install it first"
    exit 1
fi

# run the function to change the MAC address
change_mac
