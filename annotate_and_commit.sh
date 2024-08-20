#!/bin/bash

PHOTO_DIR="/home/fuzib/wildlife_camera/photos"
ANNOTATION_SOURCE="Ollama:7b" 
AI_MODEL="llava:7b" 
GIT_REPO_DIR="/home/fuzib/Documents/GitHub/Embedded-Linux-exam-2024"  # Git repository path
DATE_DIR=$(date +"%Y%m%d")  # Create a date-based directory

# Organize Files into Date Directory
echo "Organizing files into date-based directory..."

mkdir -p "$PHOTO_DIR/$DATE_DIR"
mv $PHOTO_DIR/*.jpg $PHOTO_DIR/$DATE_DIR/ 2>/dev/null
mv $PHOTO_DIR/*.json $PHOTO_DIR/$DATE_DIR/ 2>/dev/null

echo "Files organized."

# Annotate Photos
echo "Starting annotation process..."

for photo in "$PHOTO_DIR/$DATE_DIR"/*.jpg; do
    # Determine the corresponding JSON file
    json_file="${photo%.jpg}.json"

    if [ -f "$json_file" ]; then
        # Check if the JSON file already has an annotation
        if jq -e 'has("Annotation")' "$json_file" > /dev/null; then
            echo "Skipping $photo as it is already annotated."
            continue
        fi
        
        echo "Annotating $photo..."
        
        # Run Ollama to get the annotation
        annotation=$(ollama run $AI_MODEL "describe $photo in a short sentence")

        # Ensure the annotation text is properly escaped for JSON
        escaped_annotation=$(echo "$annotation" | jq -R .)

        # Update the JSON file with the annotation
        jq ". += {\"Annotation\": {\"Source\": \"$ANNOTATION_SOURCE\", \"Text\": $escaped_annotation}}" "$json_file" > temp.json
        mv temp.json "$json_file"

        echo "Annotated $photo and updated $json_file"
    else
        echo "Warning: JSON file not found for $photo"
    fi
done

echo "Annotation process completed."

# Commit Annotated JSON Files to Git
echo "Starting Git commit process..."

cd "$GIT_REPO_DIR" || { echo "Git repository directory not found!"; exit 1; }

# Copy annotated JSON files to the Git repository
mkdir -p "$GIT_REPO_DIR/annotated_json/$DATE_DIR"
cp "$PHOTO_DIR/$DATE_DIR"/*.json "$GIT_REPO_DIR/annotated_json/$DATE_DIR/"

# Add and commit the JSON files
git add "annotated_json/$DATE_DIR/"*.json
git commit -m "Added AI-based annotations to wildlife photos on $DATE_DIR"
git push origin main

echo "Git commit process completed."

