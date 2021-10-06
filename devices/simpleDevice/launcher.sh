#!/bin/bash

if [ -f ./../../.env ]; then
  export $(echo $(cat ./../../.env | sed 's/#.*//g'| xargs) | envsubst)
fi

NUM=$1
STATUS=$2
TIME=$3
EXP_NAME=$4
HOW_MANY=$5
HOW_OFTEN=$6
STEP=$7
PAYLOAD_BYTE=$8

echo ${FIWARE_IP}
echo ${IOTA_NORTH_PORT}
echo ${MOSQUITTO_CONNECION_STR}
curl \
    --max-time 10 \
    --connect-timeout 2 \
    --retry 5 \
    --retry-delay 0 \
    --retry-max-time 40 \
  -iX POST \
  "http:/${FIWARE_IP}:${IOTA_NORTH_PORT}/iot/devices" \
  -H 'Content-Type: application/json' \
  -H 'fiware-service: openiot' \
  -H 'fiware-servicepath: /' \
  -d '{
  "devices": [
    {
      "device_id":   "'"device$NUM"'",
      "entity_name": "'"urn:ngsi-ld:device:$NUM"'",
      "entity_type": "Device",
      "transport": "MQTT",
      "commands": [
        { "name": "on", "type": "command" },
        { "name": "off", "type": "command" }
       ],
      "attributes": [
        { "object_id": "s", "name": "Status", "type": "Boolean" },
        { "object_id": "time", "name": "DeviceTime", "type": "Integer" },
        { "object_id": "p", "name": "Payload", "type": "String" }
     ]
    }
  ]
}' &>/dev/null &

echo "post post"
echo $(pwd)
echo "connections str=${MOSQUITTO_CONNECTION_STR}"
#pass NUM to docker as env variable
docker run \
  --env ID=${NUM} \
  --env STATUS=${STATUS} \
  --env TIME=${TIME} \
  --env EXP_NAME=${EXP_NAME} \
  --env HOW_MANY=${HOW_MANY} \
  --env HOW_OFTEN=${HOW_OFTEN} \
  --env STEP=${STEP} \
  --env PAYLOAD_BYTE=${PAYLOAD_BYTE} \
  --env MOSQUITTO=${MOSQUITTO_CONNECTION_STR} \
  --env MOSQUITTO_PORT=${MOSQUITTO_PORT_EXT} \
  --name device${NUM} \
  -v ${ROOT}/${CODE_FOLDER}/devices/simpleDevice/mylogs:/tmp/test/mylogs \
  monte/device
