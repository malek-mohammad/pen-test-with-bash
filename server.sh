#!/bin/bash

function start_server()
{
    # We check for open ports locally	
    for port in $(seq 9000 9001); do
        if ! (echo > /dev/tcp/localhost/$port) >/dev/null 2>&1; then
            # We listen on the open port found and redirect standard input to file descriptor 3
            echo "Starting server on port $port..."
            exec 3<&0
	    nc -lnv 0.0.0.0 $port <&3
	    exit 0
        fi
    done
    echo "All ports are in use. Please try again later."
    exit 1
}

start_server



