#!/bin/bash
if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

echo "stop fiware on ${FIWARE_IP}"
ssh ${USER}@${FIWARE_IP}  docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-fiware.yml down

echo "stop draco on ${DRACO_IP}"
ssh ${USER}@${DRACO_IP}  docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-draco.yml down

echo "stop devices on ${DEVICE_IP}"
ssh ${USER}@${DEVICE_IP} docker ps --filter name=device* --filter status=running -aq | xargs docker stop
ssh ${USER}@${DEVICE_IP} 'docker rm $(docker container ls -aq --filter name=device*) -f'

echo "stop consumer on ${KAFKACONSUMER_IP}"
ssh ${USER}@${KAFKACONSUMER_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-pythonconsumer.yml down
