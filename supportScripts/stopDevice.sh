#!/bin/bash
if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

echo "stop devices on ${DEVICE_IP}"
ssh ${USER}@${DEVICE_IP} docker ps --filter name=device* --filter status=running -aq | xargs docker stop
ssh ${USER}@${DEVICE_IP} 'docker rm $(docker container ls -aq --filter name=device*) -f'
