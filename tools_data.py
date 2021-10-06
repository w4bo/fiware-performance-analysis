import numpy as np
import pandas as pd
import datetime
from matplotlib import pyplot as plt

import sys
import os
import glob

def getExperimentsInSet(experiment_set):
    res = os.listdir(experiment_set)
    res.reverse()
    return res

def readAggregateDevices(experiment_set, experiment_name):
    experiments = os.listdir(experiment_set)
    devices = pd.DataFrame(
        columns=["deviceID", "status", "datetime"]
        #dtype={'DeviceID'->'String', 'Status'->'Bool', 'Timestamp'->'Int64'}
    )
    for device_file in os.listdir(experiment_set+"/"+experiment_name+"/devices"):
        if(device_file.endswith(".csv")):
            device = pd.read_csv(
                experiment_set+"/"+experiment_name+"/devices/"+device_file, 
                header=None,
                names=["deviceID", "status", "datetime"],
                dtype={'deviceID':'str', 'status':'str', 'datetime':'Int64'}
            )
            devices = pd.concat([devices, device])
    devices["datetime"] = pd.to_datetime(devices["datetime"], unit="ms")

    return devices

def readConsumer(experiment_set, experiment_name):
    try:
        result = pd.read_csv(
            experiment_set+"/"+experiment_name+"/consumer/"+experiment_name+".csv",
            header=None,
            names=["Device ID", "Device Status", "Kafka Timestamp", "Draco Timestamp", "Device Timestamp", "Consumer Timestamp"],
            dtype={
                "Device ID":'str',
                "Device Status":'str',
                "Kafka Timestamp": 'str',
                "Draco Timestamp": 'str',
                "Device Timestamp": 'str',
                "Consumer Timestamp": 'str'
            }
        )
    except:
        result = pd.DataFrame(
            columns=["Device ID", "Device Status", "Kafka Timestamp", "Draco Timestamp", "Device Timestamp", "Consumer Timestamp"]
        )
    result = result.replace("None", np.nan).dropna()
    
    
    result["datetime"] = pd.to_datetime(result["Device Timestamp"], unit="ms")
    result["Kafka Timestamp"] = result["Kafka Timestamp"].astype("int64", copy=False)
    result["Draco Timestamp"] = result["Draco Timestamp"].astype("int64", copy=False)
    result["Device Timestamp"] = result["Device Timestamp"].astype("int64", copy=False)
    result["Consumer Timestamp"] = result["Consumer Timestamp"].astype("int64", copy=False)

    
    result["Delay Draco/Device"] = result["Draco Timestamp"] - result["Device Timestamp"]
    result["Delay Kafka/Draco"] = result["Kafka Timestamp"] - result["Draco Timestamp"]
    result["Delay Kafka/Device"] = result["Kafka Timestamp"] - result["Device Timestamp"]
    result["Delay Consumer/Device"] = result["Consumer Timestamp"] - result["Device Timestamp"]
    result["Delay Kafka Consumer"] = result["Consumer Timestamp"] - result["Kafka Timestamp"]


    return result

def paramsToMessageCount(params):
    return int(params[0]) * (1000/int(params[1]) * int(params[3]))