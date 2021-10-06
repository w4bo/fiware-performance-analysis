import sys
import os
import matplotlib.pyplot as plt
import pandas as pd
import math
from matplotlib.ticker import FuncFormatter
import numpy as np
import datetime

import sys
import os
import glob
import math

import tools_data

SMALL_SIZE = 8
MEDIUM_SIZE = 10
BIGGER_SIZE = 12

# plt.rcParams.update({'font.size': 12})
plt.rc('font', size=SMALL_SIZE)          # controls default text sizes
plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
plt.rc('axes', labelsize=MEDIUM_SIZE)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('ytick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.rc('figure', titlesize=BIGGER_SIZE)  # fontsize of the figure title

# format a time delta
def format_func(x, pos):
    hours = int(x//3600)
    minutes = int((x%3600)//60)
    seconds = int(x%60)
    return "{:d}:{:02d}:{:02d}".format(hours, minutes, seconds)

timedelta_formatter = FuncFormatter(format_func)

def graphMatrixTimeCount(experiment_set, variable, fixed_params_list, subplot_title, ascending=True):
    print(experiment_set)
    index_meaning = {
        0: "Devices",
        1: "Period",
        2: "Messages",
        3: "Subscriptions", 
        4: "Freq Increment Time",
        5: "Freq Increment Step",
        6: "Payload",
        7: "Date",
        8: "Time"
    }
    um = {
        1: "ms",
        6: "Byte",
    }
    
    experiments = tools_data.getExperimentsInSet(experiment_set)
    
    experiments.sort(key = lambda x: int(x.split("_")[variable]), reverse = not ascending)
    base_params = experiments[0].split("_")
    
    ny = math.ceil(len(experiments) / 2)
    nx = 1 if len(experiments) == 1 else 2
    fig, ax = plt.subplots(nrows=ny, ncols=nx, figsize=(3 * ny, 4 * nx))

    def time_count(ax, devices, consumer, title):
        res = pd.DataFrame()
        res["Device"] = devices.resample("1s", on="datetime").count()["datetime"]
        res["Draco"] = consumer.resample("1s", on="datetime").count()["Draco Timestamp"]
        res["Kafka Consumer"] = consumer.resample("1s", on="datetime").count()["Consumer Timestamp"]
        res = res.reset_index()
        res["datetime"] = (res["datetime"] - res["datetime"].min()).apply(lambda x: x) # strfdelta(x, '%H:%M:%S'))

        ax = res["Device"].plot(ax=ax, linewidth=10)
        ax = res["Draco"].plot(ax=ax, linewidth=5)
        ax = res["Kafka Consumer"].plot(ax=ax, linewidth=2)

        ax.set_xlabel("Time")
        ax.set_ylabel("Messages")
        ax.set_title(title)
        ax.xaxis.set_major_formatter(timedelta_formatter)
        # ax.set_xticklabels(ax.get_xticklabels(), rotation=70)
        ax.tick_params(axis='x', rotation=45)
        # plt.xticks(rotation=70)


    i = 0
    for experiment in experiments:
        print(experiment)
        params = experiment.split("_")
        params = [int(p) for p in params]

        consumer = tools_data.readConsumer(experiment_set, experiment)
        device_aggregate = tools_data.readAggregateDevices(experiment_set, experiment)
        time_count(ax[int(i/2)][i%2], device_aggregate, consumer, subplot_title(params))
        i += 1

    
    if len(experiments) < (nx * ny):
        ax.flat[-1].set_visible(False)
    
    i -= 1
    ax[int(i/2)][i%2].legend()
    
    title_string = ""
    for title_index in fixed_params_list:
        title_string += "{} = {}{}, ".format(index_meaning[title_index], base_params[title_index], um[title_index] if title_index in um else "")
    title_string = title_string[:-2]
        
    fig.suptitle(title_string)
    fig.tight_layout()
    
def graphMatrixTimeDelay(experiment_set, variable, fixed_params_list, subplot_title, ascending=True):
    print(experiment_set)
    index_meaning = {
        0: "Devices",
        1: "Period",
        2: "Messages",
        3: "Subscriptions", 
        4: "Freq Increment Time",
        5: "Freq Increment Step",
        6: "Payload",
        7: "Date",
        8: "Time"
    }
    um = {
        1: "ms",
        6: "Byte",
    }
    
    experiments = tools_data.getExperimentsInSet(experiment_set)
    
    experiments.sort(key = lambda x: int(x.split("_")[variable]), reverse = not ascending)
    base_params = experiments[0].split("_")
    
    ny = math.ceil(len(experiments) / 2)
    nx = 1 if len(experiments) == 1 else 2
    fig, ax = plt.subplots(nrows=ny, ncols=nx, figsize=(3 * ny, 4 * nx))

    def time_delay(ax, consumer, title):
        delayDracoDevice = consumer.resample("1s", on='datetime').mean()["Delay Draco/Device"]
        delayKafkaDraco = consumer.resample("1s", on='datetime').mean()["Delay Kafka/Draco"]
        delayKafkaConsumer = consumer.resample("1s", on='datetime').mean()["Delay Kafka Consumer"]

        res = pd.DataFrame()
        res["Draco"] = delayDracoDevice
        res["Kafka/Draco"] = delayKafkaDraco
        res["Kafka Consumer"] = delayKafkaConsumer
        res = res.reset_index()
        res["datetime"] = (res["datetime"] - res["datetime"].min()).apply(lambda x: x) # strfdelta(x, '%H:%M:%S'))

        ax = res["Draco"].plot(ax=ax, linewidth=10)
        ax = res["Kafka/Draco"].plot(ax=ax, linewidth=5)
        ax = res["Kafka Consumer"].plot(ax=ax, linewidth=2)

        ax.set_xlabel("Time")
        ax.set_ylabel("Delay (ms)")
        ax.set_title(title)
        ax.xaxis.set_major_formatter(timedelta_formatter)
        ax.tick_params(axis='x', rotation=45)


    i = 0
    for experiment in experiments:
        print(experiment)
        params = experiment.split("_")
        params = [int(p) for p in params]

        consumer = tools_data.readConsumer(experiment_set, experiment)
        time_delay(ax[int(i/2)][i%2], consumer, subplot_title(params))
        i += 1

    
    if len(experiments) < (nx * ny):
        ax.flat[-1].set_visible(False)
    
    i -= 1
    ax[int(i/2)][i%2].legend()
    
    title_string = ""
    for title_index in fixed_params_list:
        title_string += "{} = {}{}, ".format(index_meaning[title_index], base_params[title_index], um[title_index] if title_index in um else "")
    title_string = title_string[:-2]
        
    fig.suptitle(title_string)
    fig.tight_layout()
    
def cumulative(experiment_set, xlabel, ylabel, mapper, mapper2):
    fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(4, 3))
    metrics = {}
    experiments = os.listdir(experiment_set)
    for experiment in experiments:
        consumer = tools_data.readConsumer(experiment_set, experiment) # read consumer data
        devices = tools_data.readAggregateDevices(experiment_set, experiment) # read data from devices, the two can differ due to message loss
        params = experiment.split("_")
        label = mapper(params)
        metrics[label] = mapper2(consumer, devices)
       
    result = pd.DataFrame.from_dict(metrics, orient="index")
    result.index = result.index.astype(int)
    result = result.sort_index()  
    
    ax = result.plot(ax=ax, kind="bar", legend=False)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_xticklabels([int(x) for x in result.index])
    fig.tight_layout()
    #return fig