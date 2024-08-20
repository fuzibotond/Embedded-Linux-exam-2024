import paho.mqtt.client as mqtt
import subprocess
import logging
import json

# Setup logging
logging.basicConfig(filename='/home/fuzib/wildlife_camera/logs/mqtt_listener.log', level=logging.INFO)

def on_message(client, userdata, message):
    logging.info(f"Received message on topic {message.topic}: {message.payload.decode()}")
    try:
        payload = json.loads(message.payload.decode())
        # Check if the payload contains the correct structure
        if "wiper_angle" in payload and "rain_detect" in payload:
            logging.info("Valid JSON received. Executing take_photo.sh with 'External'")
            subprocess.run(["/home/fuzib/take_photo.sh", "External"])
        else:
            logging.error("Received JSON does not contain expected keys")
    except json.JSONDecodeError:
        logging.error("Received malformed JSON")

client = mqtt.Client()
client.on_message = on_message
client.connect("192.168.8.32", 1883, 60)
client.subscribe("wildlife/trigger")
client.loop_forever()
