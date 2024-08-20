#!/bin/bash

DRONE_ID="WILDDRONE-001"
CAMERA_IP="192.168.8.32"
PHOTO_DIR="/home/fuzib/wildlife_camera/photos"
LOCAL_PHOTO_DIR="/home/fuzib/wildlife_camera/photos"
DRONE_LOG="/home/fuzib/Embedded-Linux-exam-2024/drone_flight.log"
WIFI_LOG_DB="/home/fuzib/Embedded-Linux-exam-2024/wifi_signal_log.db"
SSH_TIMEOUT=10  # Timeout in seconds for SSH commands
CAMERA_SSID="H158-381_4C0D_5G"  # Replace with the actual SSID of the camera

# Function to check if the camera SSID is in range
function check_ssid {
    nmcli dev wifi | grep -q "$CAMERA_SSID"
}

# Function to sync time with the wildlife camera
function sync_time_with_camera {
    echo "$(date): Syncing time with the wildlife camera" | tee -a $DRONE_LOG
    # Simulate time sync with the Raspberry Pi (replace with the actual command if available)
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "sudo date -s \"$(date)\""
}

# Function to offload photos from the wildlife camera
function offload_photos {
    echo "$(date): Offloading photos from the wildlife camera" | tee -a $DRONE_LOG

    # Ensure the photo directory exists on the Raspberry Pi
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "mkdir -p $PHOTO_DIR"
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "mkdir -p /tmp/drone_temp_photos"
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "mkdir -p $PHOTO_DIR/processed"

    # Copy photos that have a corresponding JSON file and move them to the processed directory
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "
        cd $PHOTO_DIR && for photo in *.jpg; do
            json_file=\${photo%.jpg}.json
            if [ -f \"\$json_file\" ]; then
                cp \"\$photo\" \"/tmp/drone_temp_photos/\"
                cp \"\$json_file\" \"/tmp/drone_temp_photos/\"
                mv \"\$photo\" \"$PHOTO_DIR/processed/\"
                mv \"\$json_file\" \"$PHOTO_DIR/processed/\"
            fi
        done"

    # Rsync the photos and JSON files from the temporary directory to a date-based directory on the laptop
    local DATE_DIR=$(date +"%Y%m%d")
    mkdir -p "$LOCAL_PHOTO_DIR/$DATE_DIR"
    rsync -avz fuzib@$CAMERA_IP:/tmp/drone_temp_photos/ "$LOCAL_PHOTO_DIR/$DATE_DIR/"

    # Clean up the temporary directory on the Raspberry Pi
    timeout $SSH_TIMEOUT ssh fuzib@$CAMERA_IP "rm -r /tmp/drone_temp_photos"

    # Process the copied files and add the "Drone Copy" annotation
    for json_file in "$LOCAL_PHOTO_DIR/$DATE_DIR"/*.json; do
        if [ -f "$json_file" ]; then
            epoch_time=$(date +%s)
            jq ". += {\"Drone Copy\": {\"Drone ID\": \"$DRONE_ID\", \"Seconds Epoch\": $epoch_time}}" "$json_file" > temp.json
            if [ $? -eq 0 ]; then
                mv temp.json "$json_file"
            else
                echo "Failed to update JSON: $json_file" | tee -a $DRONE_LOG
                rm temp.json  # Clean up if jq failed
            fi
        else
            echo "JSON file not found: $json_file" | tee -a $DRONE_LOG
        fi
    done
}


# Function to log WiFi signal quality
function log_wifi_signal {
    local signal_quality
    local signal_level

    if grep -q "$CAMERA_SSID" /proc/net/wireless; then
        signal_quality=$(grep $CAMERA_SSID /proc/net/wireless | awk '{print $3}' | tr -d '.')
        signal_level=$(grep $CAMERA_SSID /proc/net/wireless | awk '{print $4}' | tr -d '.')

        sqlite3 $WIFI_LOG_DB <<EOF
CREATE TABLE IF NOT EXISTS wifi_signal (
    timestamp INTEGER,
    ssid TEXT,
    signal_quality INTEGER,
    signal_level INTEGER
);
INSERT INTO wifi_signal (timestamp, ssid, signal_quality, signal_level)
VALUES ($(date +%s), '$CAMERA_SSID', $signal_quality, $signal_level);
EOF

        echo "$(date): WiFi signal logged successfully." | tee -a $DRONE_LOG
    else
        echo "$(date): WiFi signal for SSID '$CAMERA_SSID' not found." | tee -a $DRONE_LOG
    fi
}

echo "$(date): Drone mission started" | tee -a $DRONE_LOG

while true; do
    if check_ssid; then
        echo "$(date): Wildlife camera found" | tee -a $DRONE_LOG
        sync_time_with_camera
        echo "Camera sync is done."
        offload_photos
        echo "Offload photos is done!"
        log_wifi_signal
	echo "wifi signal logging is ended"
	./annotate_and_commit.sh
        echo "Everything is done... the drone left."
    else
        echo "$(date): Wildlife camera not in range, continuing search..." | tee -a $DRONE_LOG
    fi
    
    echo "$(date): Loop iteration completed. Waiting 10 seconds before the next cycle..." | tee -a $DRONE_LOG
    sleep 10  # Wait for 10 seconds before checking again
done



