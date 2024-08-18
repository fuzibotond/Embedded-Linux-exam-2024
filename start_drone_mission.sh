#!/bin/bash

# Start drone flight script
./drone_flight.sh &

# Start Wi-Fi signal logging script
./log_wifi_signal.sh &

# Wait for drone flight to finish (you can add conditions to stop if needed)
wait

# Annotate photos
./annotate_photo.sh

# Commit metadata to Git
./commit_metadata.sh

