#!/bin/bash

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

IFS=','
[ ! -f ${LOG_FILE} ] && { echo "${LOG_FILE} file not found"; exit 99; }
while read version folder experiment
do
	#echo "Version : $version"
	#echo "Folder : $folder"
	#echo "Experiment : $experiment"
  echo "____"
  echo ${version} ${folder} ${experiment}
  path="${DATA_FOLDER}/${version}/${folder}/${experiment}"
  mkdir -p ${path}
  mkdir -p ${path}/consumer
  mkdir -p ${path}/devices

  if [ -f "${path}/consumer/${experiment}.csv" ]; then
    echo "consumer exists"
  else
    echo "must download consumer from ${KAFKACONSUMER_IP}"
    # we assume that in every machine the folder is in the same path
    scp ${USER}@${KAFKACONSUMER_IP}:$(pwd)/pykafkaConsumer/mylogs/${experiment}.csv ${path}/consumer/
  fi

  deviceNum=$(echo ${experiment}| cut -d'_' -f 1)
  echo "expect ${deviceNum} devices"

  for (( i=0; i<${deviceNum}; i++ ))
  do
    deviceID=$((1000+${i}))
    echo ${deviceID}
    if [ -f "${path}/devices/term${deviceID}.csv" ]; then
      echo "file exists"
    else
      echo "missing device, download from ${DEVICE_IP}"
      scp ${USER}@${DEVICE_IP}:$(pwd)/devices/simpleDevice/mylogs/${experiment}/term${deviceID}.csv ${path}/devices
    fi
  done

done < ${LOG_FILE}
