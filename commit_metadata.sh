#!/bin/bash

METADATA_DIR="/home/linux/drone_photos"
REPO_DIR="/home/linux/git_repo"
LOGFILE="/home/linux/git_commit.log"

echo "$(date) - Starting Git commit process." >> "$LOGFILE"

# Copy the metadata files to the git repository
cp "$METADATA_DIR"/*.json "$REPO_DIR/"

# Navigate to the repository
cd "$REPO_DIR" || { echo "$(date) - Failed to navigate to the repository." >> "$LOGFILE"; exit 1; }

# Add, commit, and push the changes
git add *.json
git commit -m "Added annotated metadata files"
git push origin main

if [ $? -eq 0 ]; then
    echo "$(date) - Git commit and push completed successfully." >> "$LOGFILE"
else
    echo "$(date) - Git commit and push failed." >> "$LOGFILE"
fi

