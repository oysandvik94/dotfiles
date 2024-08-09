# Function to send notification
notify_command_complete() {
    local exit_status=$?
    local command="$1"
    local duration="$2"
    local title="Command Finished"
    local message="Command took $duration seconds"

    if [ $exit_status -eq 0 ]; then
        message+=" and succeeded."
    else
        message+=" and failed with status $exit_status."
    fi

    notify-send "$title" "$message"
}

# Function to watch files and run command
watch_and_run() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: watch_and_run <file_pattern> <command>"
        return 1
    fi

    local file_pattern="$1"
    shift
    local command="$@"

    echo "Watching files matching pattern: $file_pattern"
    echo "Running command on changes: $command"

    eval "$file_pattern" | entr -r zsh -c '
    start_time=$(date +%s)
    '"$command"'
    exit_status=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    notify-send "Command Finished" "Command took $duration seconds and '"$([[ $exit_status -eq 0 ]] && echo 'succeeded' || echo "failed with status $exit_status")"'"
  '
}
