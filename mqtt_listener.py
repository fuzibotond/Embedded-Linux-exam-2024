import paho.mqtt.client as mqtt
import subprocess
import logging
import json

# Setup logging
logging.basicConfig(filename='/home/fuzib/wildlife_camera/logs/mqtt_listener.log', level=logging.INFO)

def on_message(client, userdata, message):
    logging.info(f"Received message on topic {message.topic}: {message.payload.decode()}")
    # Trigger photo capture on any message
    logging.info("Trigger received. Executing take_photo.sh with 'External'")
    subprocess.run(["/home/fuzib/take_photo.sh", "External"])

client = mqtt.Client()
client.on_message = on_message
client.connect("192.168.8.32", 1883, 60)
client.subscribe("/wildlife/trigger")
client.loop_forever()
