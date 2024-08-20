import paho.mqtt.client as mqtt
import serial
import json
import time

# Use /dev/ttyACM0 instead of /dev/serial0
ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)
current_angle = 0
last_rain_state = 0



# Function to send wiper command to Pico
def send_wiper_command(angle):
    global current_angle
    if angle != current_angle:
        command = json.dumps({"wiper_angle": angle})
        ser.write(command.encode('utf-8'))
        ser.flush()
        print(f"Sent to Pico: {command}")
        current_angle = angle

# MQTT callback function
def on_message(client, userdata, message):
    global last_rain_state

    if message.topic == "wildlife/rain_data":
        data = json.loads(message.payload.decode('utf-8'))
        print(f"Received from MQTT: {data}")
        rain_detected = data.get("rain_detect", 0)

        # Only trigger if the rain detection state changes from 0 to 1
        if rain_detected == 1 and last_rain_state == 0:
            print("Rain detected! Activating wiper...")
            send_wiper_command(30)  # Move to 30 degrees
            time.sleep(2)           # Wait for 2 seconds
            send_wiper_command(0)    # Move back to 0 degrees
            last_rain_state = 1  # Update the state to avoid retriggering

        # Reset the state when no rain is detected
        if rain_detected == 0:
            last_rain_state = 0

# Initialize MQTT client
client = mqtt.Client()
client.on_message = on_message

client.connect("192.168.8.32", 1883, 60)  
client.subscribe("wildlife/rain_data")

client.loop_forever()
