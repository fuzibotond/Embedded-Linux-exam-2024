#include <ESP8266WiFi.h>
#include <PubSubClient.h>

// Configuration
#define WIFI_SSID       "H158-381_4C0D"
#define WIFI_PASSWORD    ""
#define MQTT_SERVER      "192.168.8.32"
#define MQTT_SERVERPORT  1883 
#define MQTT_USERNAME    ""
#define MQTT_KEY         ""
#define MQTT_TOPIC       "/wildlife/trigger"  

// WiFi
#include <ESP8266WiFiMulti.h>
ESP8266WiFiMulti WiFiMulti;
const uint32_t conn_tout_ms = 5000;

// Counter
#define GPIO_INTERRUPT_PIN 4
#define DEBOUNCE_TIME 100 
volatile unsigned long count_prev_time;
volatile unsigned long count;

// MQTT
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"
WiFiClient wifi_client;
Adafruit_MQTT_Client mqtt(&wifi_client, MQTT_SERVER, MQTT_SERVERPORT, MQTT_USERNAME, MQTT_KEY);
Adafruit_MQTT_Publish count_mqtt_publish = Adafruit_MQTT_Publish(&mqtt, MQTT_USERNAME MQTT_TOPIC);

// Debug
#define DEBUG_INTERVAL 2000
unsigned long prev_debug_time;

volatile bool publish_flag = false; // Flag to indicate publishing

ICACHE_RAM_ATTR void count_isr() {
    if (count_prev_time + DEBOUNCE_TIME < millis() || count_prev_time > millis()) {
        count_prev_time = millis(); 
        count++;
        publish_flag = true;
        Serial.println("Button pressed, ready to publish!");
    }
}


void debug(const char *s)
{
  Serial.print (millis());
  Serial.print (" ");
  Serial.println(s);
}

void mqtt_connect()
{
  int8_t ret;
  int retry_count = 0;
  const int max_retries = 3; // Limit retries to avoid WDT reset

  while (!mqtt.connected() && retry_count < max_retries) {
    debug("Connecting to MQTT... ");
    ret = mqtt.connect();
    if (ret == 0) {
      debug("MQTT Connected");
      return;
    } else {
      Serial.println(mqtt.connectErrorString(ret));
      debug("Retrying MQTT connection in 5 seconds...");
      mqtt.disconnect();
      delay(5000);  // wait 5 seconds
      retry_count++;
    }
  }

  if (retry_count == max_retries) {
    debug("Failed to connect to MQTT, skipping this cycle.");
  }
}

void print_wifi_status() {
  Serial.print("WiFi connected: ");
  Serial.print(WiFi.SSID());
  Serial.print(" ");
  Serial.print(WiFi.localIP());
  Serial.println();
}


void setup()
{
  // Count setup
  count_prev_time = millis();
  count = 0;
  pinMode(GPIO_INTERRUPT_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(GPIO_INTERRUPT_PIN), count_isr, FALLING);

  // Serial setup
  Serial.begin(115200);
  delay(10);
  debug("Boot");

  // WiFi setup
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(WIFI_SSID, WIFI_PASSWORD);
  if(WiFiMulti.run(conn_tout_ms) == WL_CONNECTED)
  {
    print_wifi_status();
  }
  else
  {
    debug("Unable to connect");
  }
  // Test MQTT publish directly

  mqtt_connect();
  if (!count_mqtt_publish.publish("Test message from ESP8266")) {
    Serial.println("MQTT test message failed");
  } else {
    Serial.println("MQTT test message sent successfully");
  }
}

void publish_data() {
    if (publish_flag) {
        const char* payload = "1";  // Indicate an external trigger event

        Serial.print(millis());
        Serial.print(" Publishing: ");
        Serial.println(payload);

        if(WiFiMulti.run(conn_tout_ms) == WL_CONNECTED) {
            print_wifi_status();
            
            mqtt_connect();
            if (!count_mqtt_publish.publish(payload)) {
                Serial.println("MQTT publish failed");
            } else {
                Serial.println("MQTT publish succeeded");
            }
        }
        publish_flag = false; // Reset the flag
    }
}



void loop()
{
  // Check if we need to publish data
  publish_data();
   
  // Debug information to monitor the system status
  if (millis() - prev_debug_time >= DEBUG_INTERVAL)
  {
    prev_debug_time = millis();
    Serial.print(millis());
    Serial.print(" ");
    Serial.println(count);
  }
}
