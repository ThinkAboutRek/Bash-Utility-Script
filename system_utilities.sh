#!/bin/bash

# Log file
LOG_FILE="system_utilities.log"

# Check if log file exists, if not, create it
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" || { echo "Error: Could not create log file. Check permissions."; exit 1; }
fi

# Function to log system login information
log_login_info() {
    echo "User: $(whoami) logged in at $(date)" >> "$LOG_FILE"
}

# Function to log script commands supplied
log_script_commands() {
    echo "Script command: $@" >> "$LOG_FILE"
}

# Function to log PID of the main script process and any child processes
log_script_pid() {
    # Start a background process
    sleep 10 &  # This process will sleep in the background
    echo "Main script PID: $$" >> "$LOG_FILE"
    echo "Child script PID: $!" >> "$LOG_FILE"
}

# Check UUID collision
check_uuid_collision() {
    local uuid="$1"
    grep -q "$uuid" "$LOG_FILE" && return 0 || return 1
}

# Generate UUID v3
generate_uuid_v3() {
    local namespace="6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    local dynamic_part=$(date +%s%N)
    local name="example.com$dynamic_part"
    local hash=$(echo -n "$namespace$name" | md5sum | awk '{print $1}')
    local uuid="${hash:0:8}-${hash:8:4}-3${hash:12:3}-${hash:16:4}-${hash:20:12}"
    if check_uuid_collision "$uuid"; then
        echo "UUID collision detected, regenerating..." >> "$LOG_FILE"
        generate_uuid_v3
    else
        echo "$uuid" >> "$LOG_FILE"
        echo "Generated UUIDv3: $uuid"  # Echo to terminal
    fi
}

# Generate UUID v4
generate_uuid_v4() {
    local uuid=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
    uuid="${uuid:0:8}-${uuid:8:4}-4${uuid:12:3}-a${uuid:15:3}-${uuid:18:12}"
    if check_uuid_collision "$uuid"; then
        echo "UUID collision detected, regenerating..." >> "$LOG_FILE"
        generate_uuid_v4
    else
        echo "$uuid" >> "$LOG_FILE"
        echo "Generated UUIDv4: $uuid"  # Echo to terminal
    fi
}

# Function to categorize content in _Directory and its subdirectories
categorize_directory() {
    local root_dir="$1"

    # Ensure the directory exists
    if [ ! -d "$root_dir" ]; then
        echo "Directory '$root_dir' does not exist." >> "$LOG_FILE"
        return 1
    fi

    # Recursively process each directory and subdirectory
    find "$root_dir" -type d | while read -r dir; do
        echo "Analyzing Directory: $dir" >> "$LOG_FILE"
        # Initialize associative array for file details
        declare -A file_details

        find "$dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
            local type=${file##*.}
            local size=$(stat --format="%s" "$file")
            ((file_details[$type,count]++))
            ((file_details[$type,size]+=$size))
        done

        # Output file type details to log
        for type in "${!file_details[@]}"; do
            if [[ $type == *,count ]]; then
                local count_type=${type%,count}
                echo "  $count_type: ${file_details[$type]} files, total size: $(numfmt --to=iec ${file_details[$count_type,size]})" >> "$LOG_FILE"
            fi
        done

        # Total space used and file name lengths
        local total_space=$(du -sh "$dir" | awk '{print $1}')
        echo "  Total space used: $total_space" >> "$LOG_FILE"
        local shortest=$(find "$dir" -maxdepth 1 -type f -printf '%f\n' | awk '{ print length }' | sort -n | head -n 1)
        local longest=$(find "$dir" -maxdepth 1 -type f -printf '%f\n' | awk '{ print length }' | sort -n | tail -n 1)
        echo "  Shortest file name length: $shortest, Longest file name length: $longest" >> "$LOG_FILE"
    done
}

# Main script logic based on provided arguments
log_login_info
log_script_commands "$@"

case "$1" in
    uuid)
        if [[ $2 =~ ^[0-9]+$ ]]; then
            log_script_pid
            for ((i=0; i<$2; i++)); do
                generate_uuid_v3
                generate_uuid_v4
            done
            echo "UUID generation completed."
        else
            echo "Error: Please specify a valid number of UUIDs to generate."
            exit 1
        fi
        ;;
    directory)
        DIR="$2"
        if [ ! -d "$DIR" ]; then
            echo "Error: Directory '$DIR' does not exist." >&2
            exit 1
        fi
        log_script_pid
        categorize_directory "$DIR"
        echo "Directory analysis completed."
        ;;
    *)
        echo "Usage: $0 {uuid|directory} [directory-path or number-of-uuids]"
        exit 1
        ;;
esac
