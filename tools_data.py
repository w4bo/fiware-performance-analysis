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
    devices = pd.DataFrame(columns=[0,1,2])
    for device_file in os.listdir(experiment_set+"/"+experiment_name+"/devices"):
        if(device_file.endswith(".csv")):
            device = pd.read_csv(experiment_set+"/"+experiment_name+"/devices/"+device_file, header=None)
            devices = pd.concat([devices, device])
    devices.columns=["Device ID", "Device Status", "Device Timestamp"]
    devices["datetime"] = pd.to_datetime(devices["Device Timestamp"], unit="ms")

    return devices

def readConsumer(experiment_set, experiment_name):
    result = pd.read_csv(experiment_set+"/"+experiment_name+"/consumer/"+experiment_name+".csv", header=None, sep=",") \
        .replace("None", np.nan) \
        .dropna()
    result.columns=["Device ID", "Device Status", "Kafka Timestamp", "Draco Timestamp", "Device Timestamp", "Consumer Timestamp"]
    
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