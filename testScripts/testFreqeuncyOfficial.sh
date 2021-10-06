#!/bin/bash
EXP_NAME=$1
EXP_SET=${2}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 1000 1 1000 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 100 1 9000 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 40 1 22500 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 20 1 45000 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 10 1 90000 0 0 1000 ${EXP_NAME} ${EXP_SET}
timeout 60m ./supportScripts/launchRemoteExperiment.sh 5 8 1 112500 0 0 1000 ${EXP_NAME} ${EXP_SET}

