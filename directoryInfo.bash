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

    # Initialize file type count associative array and total size
    declare -A file_type_count
    local total_size=0

    # Use find with -print0 to handle filenames with spaces or new lines safely
    while IFS= read -r -d '' file; do
        local file_type=$(get_file_type "$file")
        local file_size=$(stat --format="%s" "$file")  # Get file size in bytes

        # Count number of files of each type
        ((file_type_count["$file_type"]++))

        # Update total size
        ((total_size += file_size))

        # Debug output
        # echo "Processing file: $file, Size: $file_size" >> "$LOG_FILE"

    done < <(find "$dir" -maxdepth 1 -type f -print0)

    # Output number of files of each type and collective size
    for file_type in "${!file_type_count[@]}"; do
        echo "$file_type: ${file_type_count["$file_type"]} files" >> "$LOG_FILE"
    done

    # Use numfmt to format the total size correctly
    local formatted_size=$(numfmt --to=iec $total_size)
    echo "Total space used: $formatted_size" >> "$LOG_FILE"

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
    echo "Error: Directory '$DIR' does not exist." >&2
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Loop through each subdirectory in the specified directory
find "$DIR" -maxdepth 1 -type d -print0 | while IFS= read -r -d '' sub_dir; do
    categorize_directory "$sub_dir"
done
