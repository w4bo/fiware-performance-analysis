from time import strftime
from json import loads
from kafka import KafkaConsumer
import os

import time
def current_milli_time():
    return round(time.time() * 1000)

timestr = strftime("%Y%m%d-%H%M%S")
print(timestr)


os.mknod("/mylogs/"+timestr+".csv")
log = open("/mylogs/"+timestr+".csv", "a")



consumer = KafkaConsumer(
    'fiware-monitoring-montelli-1997',
     bootstrap_servers=['137.204.74.57:7777'],
     auto_offset_reset='earliest',
     enable_auto_commit=True,
     group_id='my-group-montelli',
     value_deserializer=lambda x: loads(x.decode('utf-8'))
     )

print(consumer)

for message in consumer:
    if message.serialized_value_size > 10:
      #print(message.offset)
      #print(message.value)
      deviceID = message.value["id"]
      deviceStatus = message.value["Status"]
      kafkaTimestamp = message.timestamp
      dracoTimestamp = message.value["DracoTimestamp"]
      deviceTimestamp = message.value["DeviceTime"]
      consumerTimestamp = current_milli_time()
      #print("kafka timestamp", kafkaTimestamp)
      #print("draco timestamp", dracoTimestamp)
      #print("device timestamp", deviceTimestamp)
      log.write("{},{},{},{},{},{}\n".format(deviceID, deviceStatus, kafkaTimestamp, dracoTimestamp, deviceTimestamp, consumerTimestamp))
      #log.flush()
      #os.fsync(log.fileno())
    #print("_____")
