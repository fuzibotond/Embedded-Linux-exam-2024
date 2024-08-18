#!/bin/bash

ACTION=$1
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="/home/fuzib/wildlife_camera/photos/${TIMESTAMP}_${ACTION}.jpg"
JSONFILE="/home/fuzib/wildlife_camera/photos/${TIMESTAMP}_${ACTION}.json"

# Capture photo
libcamera-still -o "$FILENAME" --width 2304 --height 1296 --nopreview -t 1000

if [ $? -eq 0 ]; then
    echo "Still capture image received"
    echo "$(date) - Photo captured successfully for $ACTION detection." >> "/home/fuzib/wildlife_camera/logs/driving_script.log"

    # Get image metadata
    CREATE_DATE=$(date +"%Y-%m-%d %H:%M:%S.%3N%z")
    CREATE_SECONDS_EPOCH=$(date +%s.%3N)
    SUBJECT_DISTANCE="0.5574136009"  # Replace with actual value if available
    EXPOSURE_TIME="1/33"  # Replace with actual value if available
    ISO=200  # Replace with actual value if available

    # Create JSON metadata
    cat <<EOF > "$JSONFILE"
{
    "File Name": "$(basename $FILENAME)",
    "Create Date": "$CREATE_DATE",
    "Create Seconds Epoch": $CREATE_SECONDS_EPOCH,
    "Trigger": "$ACTION",
    "Subject Distance": $SUBJECT_DISTANCE,
    "Exposure Time": "$EXPOSURE_TIME",
    "ISO": $ISO
}
EOF

    echo "$(date) - $ACTION trigger photo saved: $FILENAME" >> "/home/fuzib/wildlife_camera/logs/driving_script.log"
else
    echo "ERROR: *** failed to open file $FILENAME ***" >> "/home/fuzib/wildlife_camera/logs/driving_script.log"
    exit 1
fi
