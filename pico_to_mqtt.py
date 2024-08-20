import serial
import paho.mqtt.client as mqtt
import json
import time
import logging


ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)

# Initialize MQTT client
client = mqtt.Client()
client.connect("192.168.8.32", 1883, 60)

last_rain_state = None  # Track the last state to prevent duplicate messages
# Configure logging
logging.basicConfig(filename='/home/fuzib/wildlife_camera/logs/wildlife_camera.log', 
                    level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')
                    
while True:
    if ser.in_waiting > 0:
        line = ser.readline().decode('utf-8').strip()
        logging.info("Received from Pico: " + line)

        print(f"Received from Pico: {line}")
        
        try:
            data = json.loads(line)
            rain_detected = data.get("rain_detect", 0)

            # Only publish if the rain state has changed
            if rain_detected != last_rain_state:
                client.publish("wildlife/rain_data", json.dumps(data))
                last_rain_state = rain_detected  # Update the state

        except json.JSONDecodeError:
            print("Received malformed JSON")
            logging.error("Received malformed JSON")

    # Short delay to avoid flooding the serial port
    time.sleep(0.1)
