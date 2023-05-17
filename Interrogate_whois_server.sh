#!/bin/bash

# Check for executables
if ! command -v whois &> /dev/null
then
    echo "whois is not found! Please install it first"
    exit 1
fi

# Get the domain name to be queried
echo "Please enter the domain name to be queried"
read domain

if [[ -z $domain ]]
then
	echo "domain cannot be empty"
	exit 1
fi


domain_regex="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"

if [[ ! "$domain" =~ $domain_regex ]] 
then
    echo "domain name s not valid"
    exit 1
fi

# Query the Whois server for the domain name
response=$(whois $domain 2>/dev/null)
whoisret=$?


if [[ whoisret -eq 0 ]]
then

	# Extract most important information from the query response
	domain_name=$(echo "$response" | grep -iE "Domain Name:" | sed 's/Domain Name://i' | tr -d ' ')

	if [[ -z $domain_name ]]
	then
		echo "domain not found"
		exit 1
	fi

	registry_expiry_date=$(echo "$response" | grep -iE "Registry Expiry Date:" | sed 's/Registry Expiry Date://i' | tr -d ' ')
	name_server=$(echo "$response" | grep -iE "Name Server:" | sed 's/Name Server://i' | tr -d ' ')
	dnssec=$(echo "$response" | grep -iE "DNSSEC:" | sed 's/DNSSEC://i' | tr -d ' ')
	registrant_name=$(echo "$response" | grep -iE "Registrant Name:" | sed 's/Registrant Name://i' | tr -d ' ')
	registrant_organization=$(echo "$response" | grep -iE "Registrant Organization:" | sed 's/Registrant Organization://i' | tr -d ' ')
	registrant_street=$(echo "$response" | grep -iE "Registrant Street:" | sed 's/Registrant Street://i' | tr -d ' ')
	registrant_city=$(echo "$response" | grep -iE "Registrant City:" | sed 's/Registrant City://i' | tr -d ' ')
	registrant_state=$(echo "$response" | grep -iE "Registrant State/Province:" | sed 's/Registrant State\/Province://i' | tr -d ' ')
	registrant_postal_code=$(echo "$response" | grep -iE "Registrant Postal Code:" | sed 's/Registrant Postal Code://i' | tr -d ' ')
	registrant_country=$(echo "$response" | grep -iE "Registrant Country:" | sed 's/Registrant Country://i' | tr -d ' ')
	registrant_phone=$(echo "$response" | grep -iE "Registrant Phone:" | sed 's/Registrant Phone://i' | tr -d ' ')
	registrant_email=$(echo "$response" | grep -iE "Registrant Email:" | sed 's/Registrant Email://i' | tr -d ' ')
	admin_name=$(echo "$response" | grep -iE "Admin Name:" | sed 's/Admin Name://i' | tr -d ' ')
	admin_phone=$(echo "$response" | grep -iE "Admin Phone:" | sed 's/Admin Phone://i' | tr -d ' ')
	admin_email=$(echo "$response" | grep -iE "Admin Email:" | sed 's/Admin Email://i' | tr -d ' ')

	# Display the information extracted
	echo "Domain Name: " $domain_name
	echo "Registry Expiry Date: " $registry_expiry_date
	echo "Name Server: " $name_server
	echo "DNSSEC: " $dnssec
	echo "Registrant Name: " $registrant_name
	echo "Registrant Organization: " $registrant_org
	echo "Registrant Street: " $registrant_street
	echo "Registrant City: " $registrant_city
	echo "Registrant State/Province: " $registrant_state
	echo "Registrant Postal Code: " $registrant_postal_code
	echo "Registrant Country: " $registrant_country
	echo "Registrant Phone: " $registrant_phone
	echo "Registrant Email: " $registrant_email
	echo "Admin Name: " $admin_name
	echo "Admin Phone: " $admin_phone
	echo "Admin Email: " $admin_email

else
	echo "whois returned error code: $whoisret"
	exit 1
fi
