#!/bin/bash

# Log file 
LOG_FILE="uuid_generator.log"

# Check if log file exists, if not, create it
if [ ! -f "$LOG_FILE" ]; then
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "Error: Could not create log file. Check permissions."
        exit 1
    fi
fi

# Function to log system login information
log_login_info() {
    echo "User: $(whoami) logged in at $(date)" >> "$LOG_FILE"
}

# Function to log script commands supplied
log_script_commands() {
    echo "Script command: $@" >> "$LOG_FILE"
}

# Function to log PID of the main script process
log_script_pid() {
    echo "Main script PID: $$" >> "$LOG_FILE"
}

generate_uuid_v3() {
    local namespace="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    local dynamic_part=$(date +%s%N) # Current timestamp in nanoseconds
    local name="example.com$dynamic_part"
    local hash=$(echo -n "$namespace$name" | md5sum | awk '{print $1}')
    local uuid="${hash:0:8}-${hash:8:4}-3${hash:12:3}-${hash:16:4}-${hash:20:12}"
    echo "$uuid"
}

generate_uuid_v4() {
    local uuid=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 2>/dev/null)
    if [ -z "$uuid" ]; then
        echo "Error: Could not access /dev/urandom or insufficient permissions."
        return 1
    fi
    uuid="${uuid:0:8}-${uuid:8:4}-4${uuid:12:3}-a${uuid:15:3}-${uuid:18:12}"
    echo "$uuid"
}

# Main script
log_login_info
log_script_pid

read -p "Enter the number of UUIDs to generate: " NUM_UUIDS
if [[ ! "$NUM_UUIDS" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a number."
    exit 1
fi

log_script_commands "Number of UUIDs: $NUM_UUIDS"

for ((i=1; i<=NUM_UUIDS; i++)); do
    uuid_v3=$(generate_uuid_v3)
    if [ -n "$uuid_v3" ]; then
        echo "$uuid_v3" >> "$LOG_FILE"
        echo "Generated UUIDv3: $uuid_v3"
    fi
    uuid_v4=$(generate_uuid_v4)
    if [ -n "$uuid_v4" ]; then
        echo "$uuid_v4" >> "$LOG_FILE"
        echo "Generated UUIDv4: $uuid_v4"
    fi
    echo ""
done
