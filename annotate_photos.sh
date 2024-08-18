#!/bin/bash

PHOTO_DIR="/home/linux/drone_photos"
LOGFILE="/home/linux/drone_annotation.log"

echo "$(date) - Annotation process started." >> "$LOGFILE"

for json_file in $(find "$PHOTO_DIR" -name "*.json" -type f); do
    photo_file="${json_file%.json}.jpg"

    if [ -f "$photo_file" ]; then
        # Use an AI tool to annotate the photo (replace with your specific tool)
        annotation=$(echo "Simulated annotation for $photo_file")

        if [ $? -eq 0 ]; then
            # Update the JSON file with the annotation
            jq --arg annotation "$annotation" '.["Annotation"] = {"Source": "Ollama:7b", "Text": $annotation}' "$json_file" > temp.json && mv temp.json "$json_file"
            echo "$(date) - Annotated $photo_file and updated $json_file" >> "$LOGFILE"
        else
            echo "$(date) - Failed to annotate $photo_file" >> "$LOGFILE"
        fi
    else
        echo "$(date) - Photo file $photo_file not found." >> "$LOGFILE"
    fi
done

