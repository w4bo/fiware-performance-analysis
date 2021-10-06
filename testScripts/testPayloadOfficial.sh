#!/bin/bash
EXP_NAME=$1
EXP_SET=$2
timeout 60m ./supportScripts/launchRemoteExperiment.sh 50 200 1 4500 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 50 200 1 4500 0 0 10000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 50 200 1 4500 0 0 50000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 50 200 1 4500 0 0 100000 ${EXP_NAME} ${EXP_SET}

