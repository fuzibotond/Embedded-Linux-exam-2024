#!/bin/bash

DB_PATH="/home/linux/drone_logs/wifi_signal.db"
WIFI_INTERFACE="wlan0"
LOG_INTERVAL=5  # Log every 5 seconds
LOGFILE="/home/linux/wifi_signal.log"

# Create the SQLite database and table if it doesn't exist
sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS wifi_log (epoch_time REAL, signal_level REAL, link_quality REAL);"

while true; do
    # Get Wi-Fi signal quality and link level
    signal_data=$(awk '/'"$WIFI_INTERFACE"'/{print int($3 * 100 / 70), $4}' /proc/net/wireless)
    epoch_time=$(date +%s.%3N)

    if [ -n "$signal_data" ]; then
        # Insert data into the SQLite database
        sqlite3 "$DB_PATH" "INSERT INTO wifi_log VALUES ($epoch_time, $signal_data);"
        echo "$(date) - Logged Wi-Fi signal data: $signal_data" >> "$LOGFILE"
    else
        echo "$(date) - Failed to retrieve Wi-Fi signal data." >> "$LOGFILE"
    fi

    sleep "$LOG_INTERVAL"
done

