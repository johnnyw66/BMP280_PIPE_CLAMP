import os
import time
import board
import busio
import wifi
import socketpool
import adafruit_minimqtt.adafruit_minimqtt as MQTT
import adafruit_bmp280
import digitalio

led = digitalio.DigitalInOut(board.LED)
led.direction = digitalio.Direction.OUTPUT

kitchen_topic = os.getenv("KITCHEN_INLET_TOPIC")
bathroom_topic = os.getenv("BATHROOM_INLET_TOPIC")

print(kitchen_topic)
print(bathroom_topic)

# BME280 global instance
bmp280_sensor = None
sht30_sensor = None

BMP280_I2C_ADDR = 0x77



# SHT30 Default I2C Address
SHT30_I2C_ADDR = 0x44

# Setup I2C bus (adjust pins if using a specific board layout)
#i2c = busio.I2C(board.SCL, board.SDA)
i2c = board.STEMMA_I2C()


def blink(dely=0.125):
    led.value = True
    time.sleep(dely)        
    led.value = False
    time.sleep(dely)        

def init_bmp280():
    
    
    """Initialize the BME280 sensor instance on the active I2C bus."""
    global bmp280_sensor
    try:
        
        bmp280_sensor = adafruit_bmp280.Adafruit_BMP280_I2C(i2c, address=0x77)

        print(f"BMP280 initialized successfully at 0x{BMP280_I2C_ADDR:02X}")
    except ValueError:
        print("VALUE ERROR")
    except Exception as e:
        print(f"Failed to initialize BME280: {e}")
        bme280_sensor = None


def read_bmp280_temp():
    """Read calibrated temperature in Celsius from the BMP280."""
    global bmp280_sensor
    if bmp280_sensor is None:
        init_bmp280()
        if bmp280_sensor is None:
            return None

    try:
        # Read temperature and round to 2 decimal places
        return round(bmp280_sensor.temperature, 2)
    except Exception as e:
        print(f"Error reading BMP280: {e}")
        return None

def init_sht30():
    """Ensure the internal heater is disabled."""
    global sht30_sensor 
    while not i2c.try_lock():
        pass
    try:
        # Command 0x3066: Disable internal heater
        i2c.writeto(SHT30_I2C_ADDR, bytes([0x30, 0x66]))
        sht30_sensor = True
    except Exception as e:
        pass
    finally:
        i2c.unlock()

def read_sht30_temp():
    """Trigger single-shot measurement and read raw bytes."""
    while not i2c.try_lock():
        pass
    try:
        # Command 0x2400: High repeatability measurement, clock stretching disabled
        i2c.writeto(SHT30_I2C_ADDR, bytes([0x24, 0x00]))
        time.sleep(0.02)  # Wait for measurement conversion (~15ms)
        
        data = bytearray(6)
        i2c.readfrom_into(SHT30_I2C_ADDR, data)
        
        # Raw 16-bit temperature
        raw_temp = (data[0] << 8) | data[1]
        
        # Sensirion conversion formula: T = -45 + 175 * (raw / (2^16 - 1))
        temperature_c = -45.0 + (175.0 * (raw_temp / 65535.0))
        return round(temperature_c, 2)
    finally:
        i2c.unlock()

# Connect to Wi-Fi
print(f"Connecting to {os.getenv('CIRCUITPY_WIFI_SSID')}...")
wifi.radio.connect(
    os.getenv("CIRCUITPY_WIFI_SSID"), 
    os.getenv("CIRCUITPY_WIFI_PASSWORD")
)
print(f"Connected! IP: {wifi.radio.ipv4_address}")

init_sht30()
init_bmp280()
print(sht30_sensor)

# Setup MQTT Client
pool = socketpool.SocketPool(wifi.radio)
mqtt_client = MQTT.MQTT(
    broker=os.getenv("MQTT_BROKER"),
    port=int(os.getenv("MQTT_PORT", 1883)),
    username=os.getenv("MQTT_USER"),
    password=os.getenv("MQTT_PASSWORD"),
    socket_pool=pool,
    is_ssl=False,
)

print("Connecting to MQTT broker...")
mqtt_client.connect()
print("MQTT connected!")


# Main Publish Loop (~6-second cadence)
while True:
    try:
        mqtt_client.loop()
        if (sht30_sensor):
            kitchen_temp = read_sht30_temp()
            mqtt_client.publish(kitchen_topic, str(kitchen_temp))
            print(f"Published to {kitchen_topic}: {kitchen_temp} °C")

        if (bmp280_sensor):
            bathroom_temp = read_bmp280_temp()
            mqtt_client.publish(bathroom_topic, str(bathroom_temp))
            print(f"Published to {bathroom_topic}: {bathroom_temp} °C")

        if (sht30_sensor):
            blink(0.125)
        if (bmp280_sensor):
            blink(0.125)
            

        time.sleep(5)

    except Exception as e:
        print(f"Error: {e}")
        time.sleep(5)
        try:
            if not mqtt_client.is_connected():
                mqtt_client.reconnect()
        except Exception as recon_err:
            print(f"Reconnection failed: {recon_err}")

