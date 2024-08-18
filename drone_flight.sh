#!/bin/bash

CAMERA_SSID="H158-381_4C0D"  
WIFI_INTERFACE="wlan0" 
DRONE_COPY_DIR="/home/linux/drone_photos" 
LOGFILE="/home/linux/drone_flight.log"
CAMERA_IP="192.168.1.100"  # Replace with actual IP address

# Start the drone flight
echo "$(date) - Drone flight started." >> "$LOGFILE"

while true; do
    # Scan for the camera SSID
    SSID_FOUND=$(iwlist $WIFI_INTERFACE scan | grep "$CAMERA_SSID")

    if [ -n "$SSID_FOUND" ]; then
        echo "$(date) - Camera SSID found: $CAMERA_SSID" >> "$LOGFILE"

        # Connect to the wildlife camera Wi-Fi
        nmcli dev wifi connect "$CAMERA_SSID"

        if [ $? -eq 0 ]; then
            echo "$(date) - Connected to the camera Wi-Fi." >> "$LOGFILE"

            # Synchronize time with the camera
            sudo ntpdate -u $CAMERA_IP  
            
            # Offload new photos and metadata
            rsync -avz --ignore-existing pi@$CAMERA_IP:/home/pi/photos/ "$DRONE_COPY_DIR"

            if [ $? -eq 0 ]; then
                echo "$(date) - Photos and metadata successfully copied." >> "$LOGFILE"

                # For each photo copied, update the metadata JSON file with drone info
                for json_file in $(find "$DRONE_COPY_DIR" -name "*.json" -type f); do
                    jq '.["Drone Copy"] = {"Drone ID": "WILDDRONE-001", "Seconds Epoch": '$(date +%s.%3N)'}' "$json_file" > temp.json && mv temp.json "$json_file"
                    echo "$(date) - Updated metadata for $json_file" >> "$LOGFILE"
                done
            else
                echo "$(date) - Failed to copy photos and metadata." >> "$LOGFILE"
            fi

            # Disconnect from the camera Wi-Fi
            nmcli dev disconnect "$WIFI_INTERFACE"
            echo "$(date) - Disconnected from the camera Wi-Fi." >> "$LOGFILE"
        else
            echo "$(date) - Failed to connect to the camera Wi-Fi." >> "$LOGFILE"
        fi
    else
        echo "$(date) - Camera SSID not found, scanning again..." >> "$LOGFILE"
    fi

    # Check every 30 seconds (adjust as necessary)
    sleep 30
done

