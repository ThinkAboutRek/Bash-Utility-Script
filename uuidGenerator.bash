#!/bin/bash

# Log file
LOG_FILE="uuid_generator.log"

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

# Function to generate UUID version 1
generate_uuid_v1() {
    local uuid=$(date +%s%N | md5sum | sed 's/\(..\)/\1:/g; s/.$//' | awk -v var=$1 '{print var "-" $0}')
    echo "$uuid"
}

# Function to generate UUID version 4
generate_uuid_v4() {
    local uuid=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 | sed 's/\(..\)/\1-/g; s/.$//' | awk -v var=$1 '{print var "-" $0}')
    echo "$uuid"
}

# Main script
log_login_info
log_script_pid

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_uuids>"
    exit 1
fi

log_script_commands "$@"

NUM_UUIDS="$1"

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

for ((i=1; i<=NUM_UUIDS; i++)); do
    # Generate UUIDv1
    generate_uuid_v1 "UUIDv1" &
    pid_uuid_v1=$!
    uuid_v1=$(generate_uuid_v1 "UUIDv1")
    echo "$uuid_v1" >> "$LOG_FILE"
    echo "Subprocess PID (UUIDv1): $pid_uuid_v1" >> "$LOG_FILE"

    # Generate UUIDv4
    generate_uuid_v4 "UUIDv4" &
    pid_uuid_v4=$!
    uuid_v4=$(generate_uuid_v4 "UUIDv4")
    echo "$uuid_v4" >> "$LOG_FILE"
    echo "Subprocess PID (UUIDv4): $pid_uuid_v4" >> "$LOG_FILE"

    echo ""
done


