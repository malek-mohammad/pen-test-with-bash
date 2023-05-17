#!/bin/bash


# We check for executables
if ! command -v dig &> /dev/null
then
    echo "dig is not found! Please install it first"
    exit 1
fi

if ! command -v dnsmap &> /dev/null
then
    echo "dnsmap is not found! Please install it first"
    exit 1
fi

# We Define regex pattern for valid domain names
domain_regex="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"

# We Get the domain name to be queried
read -p "Please enter the domain name to be queried: " domain

if [[ -z $domain ]]
then
        echo "Domain name cannot be empty"
        exit 1
fi

# We Validate the domain name using a regex pattern
if ! [[ $domain =~ $domain_regex ]]
then
    echo "Invalid domain name"
    exit 1
fi

# We prompt the user to enter a comma-separated list of DNS record types to query
read -p "Please enter a comma-separated list of DNS record types to query (e.g. A,MX,NS): " types_str

read -p "Do you want to interrogate subdomains? (e.g. y,n)" interrogate_subd

# We prompt the user if they want to interrogate the subdomains
if [[ -z $interrogate_subd ]] || [[ $interrogate_subd != 'y' && $interrogate_subd != 'n' ]]; then
    echo "Invalid input for subdomain interrogation"
    interrogate_subd='n'
fi



# We use default list of DNS record types if user input is empty
if [[ -z $types_str ]]
then
    types=("A" "MX" "NS" "TXT")
else
    # We validate the input using a regex
    if ! [[ $types_str =~ ^([[:alpha:]]+,)*[[:alpha:]]+$ ]]
    then
            echo "Invalid input. Please enter a comma-separated list of DNS record types (e.g. A,MX,NS)."
            exit 1
    fi

    # We split the comma-separated list of record types into an array
    IFS=',' read -ra types <<< "$types_str"
fi

# We loop through each DNS record type and query the DNS server
for type in "${types[@]}"
do
    echo "Querying DNS server for $type records..."
    output=$(dig "$domain" "$type" +short)
    if [[ -n "$output" ]]
    then
        echo "DNS $type records for $domain:"
        echo "$output"
        echo ""
    else
        echo "Unable to retrieve $type records for $domain"
    fi
done

# We start with subdomain interrogation
if [[ $interrogate_subd == 'y' ]]; then
	echo "Interrogating the DNS server for subdomains for $domain..."
	read -p "Do you have a subdomains wordlist file? please enter the file path? " subdomainfile
	if ! [[ -z $subdomainfile ]] && [[ -f $subdomainfile ]]; then
		output=$(dnsmap "$domain" -w "$subdomainfile")
	else
		echo "Performing dnsmap builtin subdomain interrogation"
		output=$(dnsmap "$domain")
	fi
	if [[ -n "$output" ]]
	then
		echo "DNS subdomains found for $domain:"
		echo "$output"
		echo ""
	else
		echo "Unable to retrieve subdomains for $domain"
	fi
fi


