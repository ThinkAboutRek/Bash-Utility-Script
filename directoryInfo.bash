#!/bin/bash

# Log file
LOG_FILE="directory_info.log"

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

# Function to categorize content in a directory
categorize_directory() {
    local dir="$1"
    echo "Directory: $dir" >> "$LOG_FILE"

    # Initialize file type count associative array
    declare -A file_type_count

    # List all files and directories in the given directory
    local files=$(find "$dir" -maxdepth 1 -type f)
    local dirs=$(find "$dir" -maxdepth 1 -type d)

    # Count number of files of each type and calculate collective size
    # Also find shortest and largest filename
    local total_size=0
    local shortest_name=""
    local longest_name=""
    for file in $files; do
        # Get file type and size
        local file_type=$(get_file_type "$file")
        local file_size=$(du -h "$file" | cut -f1)

        # Count number of files of each type
        ((file_type_count["$file_type"]++))

        # Update total size
        ((total_size += $(du -b "$file" | cut -f1)))

        # Update shortest and longest filename
        if [ -z "$shortest_name" ] || [ ${#file} -lt ${#shortest_name} ]; then
            shortest_name="$file"
        fi
        if [ -z "$longest_name" ] || [ ${#file} -gt ${#longest_name} ]; then
            longest_name="$file"
        fi
    done

    # Output number of files of each type and collective size
    for file_type in "${!file_type_count[@]}"; do
        echo "$file_type: ${file_type_count["$file_type"]} files" >> "$LOG_FILE"
    done
    echo "Total space used: $(numfmt --to=iec $total_size)" >> "$LOG_FILE"

    # Output shortest and longest filename
    echo "Shortest filename: $shortest_name" >> "$LOG_FILE"
    echo "Longest filename: $longest_name" >> "$LOG_FILE"

    echo "" >> "$LOG_FILE"
}

# Function to determine file type based on extension
get_file_type() {
    local file="$1"
    local extension="${file##*.}"
    case "$extension" in
        sh) echo "Shell script";;
        txt) echo "Text file";;
        jpg|jpeg|png|gif) echo "Image file";;
        *) echo "Unknown file type";;
    esac
}

# Main script
log_login_info
log_script_pid

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

log_script_commands "$@"

DIR="$1"

if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' does not exist."
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Loop through each subdirectory in the specified directory
for sub_dir in "$DIR"/*; do
    if [ -d "$sub_dir" ]; then
        categorize_directory "$sub_dir"
    fi
done

