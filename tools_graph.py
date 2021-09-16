import numpy as np
import pandas as pd
import datetime
from matplotlib import pyplot as plt

import sys
import os
import glob

import tools_data

plt.rcParams.update({'font.size': 18})

def graphType1(devices, consumer, title):
    plt.rcParams["figure.figsize"] = (15,8)

    
    res = pd.DataFrame()
    res["device"] = devices.resample("1s", on="datetime").count()["datetime"]
    res["draco"] = consumer.resample("1s", on="datetime").count()["Draco Timestamp"]
    res["endpoint"] = consumer.resample("1s", on="datetime").count()["Consumer Timestamp"]
    ax = res.plot()
    ax.set_xlabel("Time")
    ax.set_ylabel("Message Count")
    ax.set_title(title)
    ax.plot()
    
    
def graphType2(consumer, title):
    plt.rcParams["figure.figsize"] = (15,8)

    delayDracoDevice = consumer.resample("1s", on='datetime').mean()["Delay Draco/Device"]
    delayKafkaDraco = consumer.resample("1s", on='datetime').mean()["Delay Kafka/Draco"]
    delayKafkaConsumer = consumer.resample("1s", on='datetime').mean()["Delay Kafka Consumer"]

    
    
    res = pd.DataFrame()
    res["Draco"] = delayDracoDevice
    res["Kafka/Draco"] = delayKafkaDraco
    res["Kafka Consumer"] = delayKafkaConsumer
    
    ax = res.plot()
    ax.set_xlabel("time")
    ax.set_ylabel("delay (ms)")
    ax.set_title(title)
    ax.plot()
    
def graphType3(experiment_set, variable_index, xlabel, title, mapper):
    plt.rcParams["figure.figsize"] = (15,10)

    metrics = {}
    experiments = os.listdir(experiment_set)
    for experiment in experiments:
        consumer = tools_data.readConsumer(experiment_set, experiment)
        devices = tools_data.readAggregateDevices(experiment_set, experiment)
        params = experiment.split("_")
        #params = [int(p) for p in params]
        #params[0] * (1000/params[1])
        label = mapper(params)
        metrics[label] = (consumer.shape[0] / devices.shape[0]) * 100
       
    result = pd.DataFrame.from_dict(metrics, orient="index")
    result.index = result.index.astype(float)
    result = result.sort_index()  
    
    ax = result.plot(kind="bar", legend=False)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("#received / #sent")
    ax.plot()
    

def graphType4(experiment_set, variable_index, xlabel, title, mapper):
    plt.rcParams["figure.figsize"] = (15,10)

        
    metrics = {}
    experiments = os.listdir(experiment_set)
    for experiment in experiments:
        consumer = tools_data.readConsumer(experiment_set, experiment)
        params = experiment.split("_")
        #params = [int(p) for p in params]
        #label = params[0] * (1000/params[1])
        label = mapper(params)
        metrics[label] = consumer["Delay Consumer/Device"].mean()

    result = pd.DataFrame.from_dict(metrics, orient="index")
    result.index = result.index.astype(float)
    result = result.sort_index()
    
    
    ax = result.plot(kind="bar", legend=False)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("delay(ms)")
    ax.plot()