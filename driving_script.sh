#!/bin/bash

LOGFILE="/home/fuzib/wildlife_camera/logs/driving_script.log"
PHOTO_SCRIPT="/home/fuzib/take_photo.sh"
MQTT_TOPIC="/wildlife/trigger"
LAST_MOTION_TIME=0
MOTION_COOLDOWN=120  # 2 minutes cooldown
MQTT_LOG="/home/fuzib/mqtt_messages.log"
IMG_PATH="/home/fuzib/wildlife_camera/photos"

echo "$(date) - Driving script started." >> "$LOGFILE"

# Start mosquitto_sub in the background and log its output to a file
mosquitto_sub -h 192.168.8.32 -t "$MQTT_TOPIC" > "$MQTT_LOG" &

# Function to handle MQTT messages
handle_mqtt_message() {
    echo "$(date) - Received MQTT message for External trigger: $1" >> "$LOGFILE"
    if [ "$1" == "camera_error" ]; then
        echo "$(date) - Camera is not available. Skipping photo capture." >> "$LOGFILE"
    else
        bash "$PHOTO_SCRIPT" External
    fi
}

# Function to create JSON metadata for the saved photo
create_json() {
    local filepath="$1"
    local trigger_type="$2"
    local json_filepath="${filepath%.jpg}.json"

    cat <<EOF > "$json_filepath"
{
    "File Name": "$(basename "$filepath")",
    "Create Date": "$(date +"%Y-%m-%d %H:%M:%S.%3N%z")",
    "Create Seconds Epoch": "$(date +%s.%3N)",
    "Trigger": "$trigger_type",
    "Subject Distance": 0.0,  # Modify if you have actual data
    "Exposure Time": "1/33",  # Modify if you have actual data
    "ISO": 200  # Modify if you have actual data
}
EOF
}

# Function to capture photos for motion detection
capture_motion_photo() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    FILENAME1="$IMG_PATH/${TIMESTAMP}_motion1.jpg"
    FILENAME2="$IMG_PATH/${TIMESTAMP}_motion2.jpg"

    libcamera-still -o "$FILENAME1" --width 2304 --height 1296 --nopreview -t 1000
    sleep 3
    libcamera-still -o "$FILENAME2" --width 2304 --height 1296 --nopreview -t 1000

    echo "$(date) - Capturing photos for motion detection." >> "$LOGFILE"
    MOTION_DETECTED=$(python3 /home/fuzib/motion_detect.py "$FILENAME1" "$FILENAME2")

    if [[ "$MOTION_DETECTED" == *"Motion detected"* ]]; then
        echo "$(date) - Motion detected, saving photo." >> "$LOGFILE"
        SAVED_FILENAME="$IMG_PATH/${TIMESTAMP}_motion_detected.jpg"
        mv "$FILENAME2" "$SAVED_FILENAME"  # Save the image that detected motion
        create_json "$SAVED_FILENAME" "Motion"  # Create the JSON metadata
        LAST_MOTION_TIME=$(date +%s)
    else
        echo "$(date) - No motion detected. Deleting photos." >> "$LOGFILE"
        rm "$FILENAME1" "$FILENAME2"  # Clean up the photos if no motion detected
    fi
}

# Run in an infinite loop
while true; do
    CURRENT_TIME=$(date +%s)

    # Capture a photo every 5 minutes
    if (( CURRENT_TIME % 300 == 0 )); then
        echo "$(date) - Time-based photo capture." >> "$LOGFILE"
        bash "$PHOTO_SCRIPT" Time
    fi

    # Check for motion
    if (( CURRENT_TIME - LAST_MOTION_TIME > MOTION_COOLDOWN )); then
        capture_motion_photo
    fi

    # Check for MQTT messages
    if [ -s "$MQTT_LOG" ]; then
        while read -r message; do
            handle_mqtt_message "$message"
        done < "$MQTT_LOG"
        > "$MQTT_LOG"  # Clear the log file after processing
    fi

    sleep 1
done
