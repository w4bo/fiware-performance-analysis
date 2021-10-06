#!/bin/bash

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

echo "build fiware"
ssh ${USER}@${FIWARE_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-fiware.yml build

echo "build kafka consumer"
ssh ${USER}@${KAFKACONSUMER_IP} docker-compose -f  ${ROOT}/${CODE_FOLDER}/docker-compose-pythonconsumer.yml build

echo "build draco"
ssh ${USER}@${DRACO_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-draco.yml build

