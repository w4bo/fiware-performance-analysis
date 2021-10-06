#!/bin/bash

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

ssh ${USER}@${DEVICE_IP} "rm -rf ${ROOT}/${CODE_FOLDER}/devices/simpleDevice/mylogs/*"
ssh ${USER}@${KAFKACONSUMER_IP} "rm -rf ${ROOT}/${CODE_FOLDER}/pykafkaConsumer/mylogs/*"
