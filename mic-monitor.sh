#!/bin/bash

MIC_LED_PATH="/sys/class/leds/platform::micmute/brightness"
CHECK_INTERVAL=0.1

# Function to check if the LED file exists and is writable
check_led_path() {
    if [[ ! -e "$MIC_LED_PATH" ]]; then
        echo "Error: LED file $MIC_LED_PATH does not exist."
        exit 1
    fi

    if [[ ! -w "$MIC_LED_PATH" ]]; then
        echo "Error: No write permissions for $MIC_LED_PATH."
        exit 1
    fi
}

# Function to check if pactl is installed
check_pactl_installed() {
    if ! command -v pactl &> /dev/null; then
        echo "Error: 'pactl' command not found. Please install PulseAudio or PipeWire."
        exit 1
    fi
}

update_led() {
    local state="$1"
    if [[ "$state" == "yes" ]]; then
        echo 1 | tee "$MIC_LED_PATH" > /dev/null
    else
        echo 0 | tee "$MIC_LED_PATH" > /dev/null
    fi
}

get_audio_user() {
    ps aux | grep -E 'pipewire|pulseaudio|jackd' | grep -v grep | awk '{print $1}' | sort | uniq | head -n 1
}

check_microphone() {
    local audio_user="$1"

    export PULSE_RUNTIME_PATH="/run/user/$(id -u "$audio_user")/pulse"

    local active_source
    active_source=$(sudo -u "$audio_user" PULSE_RUNTIME_PATH="$PULSE_RUNTIME_PATH" pactl get-default-source 2>/dev/null)

    if [[ -z "$active_source" ]]; then
        # echo "No active microphone found."
        return
    fi

    local mute_state
    mute_state=$(sudo -u "$audio_user" PULSE_RUNTIME_PATH="$PULSE_RUNTIME_PATH" pactl get-source-mute "$active_source" 2>/dev/null | awk '{print $2}')

    local volume_state
    volume_state=$(sudo -u "$audio_user" PULSE_RUNTIME_PATH="$PULSE_RUNTIME_PATH" pactl get-source-volume "$active_source" 2>/dev/null | grep -oP '\d+%' | head -n 1)

    if [[ "$mute_state" == "yes" ]]; then
        update_led "yes"
    else
        update_led "no"
    fi
}

# Initial setup checks
check_led_path
check_pactl_installed

# echo "Starting microphone monitoring..."

while true; do
    audio_user=$(get_audio_user)

    if [[ -z "$audio_user" ]]; then
        # echo "No audio user found."
        sleep 1
        continue
    fi

    # echo "Audio is used by: $audio_user"
    check_microphone "$audio_user"
    sleep "$CHECK_INTERVAL"
done
