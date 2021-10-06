#!/bin/bash
if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

NUM_DEVICE=$1
DEVICE_TIME=$2
SUB_NUM=$3
HOW_MANY_MESSAGES=$4
HOW_OFTEN_SPEEDUP=$5
SPEEDUP=$6
PAYLOAD_BYTE=$7
GROUP_EXP="${8:-misc}"
RUN_ID="${9:-misc}"

FIRST_ID=1000

EXP_NAME=${NUM_DEVICE}_${DEVICE_TIME}_${HOW_MANY_MESSAGES}_${SUB_NUM}_${HOW_OFTEN_SPEEDUP}_${SPEEDUP}_${PAYLOAD_BYTE}_`date +"%G%m%d_%H%M%S"`
echo ${EXP_NAME}

echo "${RUN_ID},${GROUP_EXP},${EXP_NAME}" >> ${LOG_FILE}

./supportScripts/stopAll.sh

echo "setup fiware on ${FIWARE_IP}"
ssh ${USER}@${FIWARE_IP}  docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-fiware.yml up --build &>/dev/null &
echo "wait for seutp completion"
./supportScripts/wait-for-it.sh ${FIWARE_IP}:${ZOOKEEPER_EXT_PORT} --timeout=480 -- echo "zookeeper is up"
./supportScripts/wait-for-it.sh ${FIWARE_IP}:${KAFKA_EXT_PORT} --timeout=480 -- echo "kafka is up"
./supportScripts/wait-for-it.sh ${FIWARE_IP}:${MOSQUITTO_PORT_EXT} --timeout=480 -- echo "mosquitto is up"
./supportScripts/wait-for-it.sh ${FIWARE_IP}:${ORION_PORT_EXT} --timeout=480 -- echo "orion is up"
./supportScripts/wait-for-it.sh ${FIWARE_IP}:${IOTA_NORTH_PORT} --timeout=480 -- echo "iota is up"
echo "setup fiware on ${FIWARE_IP} complete"
curl -iX POST \
  "http://${FIWARE_IP}:${IOTA_NORTH_PORT}/iot/services" \
  -H 'Content-Type: application/json' \
  -H 'fiware-service: openiot' \
  -H 'fiware-servicepath: /' \
  -d '{
 "services": [
   {
     "apikey": "'"${API_KEY}"'",
     "cbroker": "'"http://orion:${ORION_PORT}"'",
     "entity_type": "Device",
     "resource": ""
   }
 ]
}' #&>/dev/null
echo "setup service group complete"

echo "setup pykafkaconsumer"
ssh ${USER}@${KAFKACONSUMER_IP} mkdir -p ${ROOT}/${CODE_FOLDER}/pykafkaConsumer/mylogs
PYC_UID=$(ssh ${USER}@${KAFKACONSUMER_IP} id -u)
PYC_GID=$(ssh ${USER}@${KAFKACONSUMER_IP} id -g)
ssh ${USER}@${KAFKACONSUMER_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-pythonconsumer.yml build --build-arg uid=${PYC_UID} --build-arg gid=${PYC_GID}
ssh ${USER}@${KAFKACONSUMER_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-pythonconsumer.yml up &>/dev/null &
echo "wait launch on ${KAFKACONSUMER_IP} completion"
count_consumer=$(($(ssh ${USER}@${KAFKACONSUMER_IP} "docker ps | grep pykafkaconsumer | wc -l")))
while [ "${count_consumer}" != 1 ]
do
  count_consumer=$(($(ssh ${USER}@${KAFKACONSUMER_IP} "docker ps | grep pykafkaconsumer | wc -l")))
  sleep 10s
done
echo "setup of pykafkaconsuer on ${KAFKACONSUMER_IP} done"


echo "setup draco on ${DRACO_IP}"
echo "wait for completion"
ssh ${USER}@${DRACO_IP} chmod -R 777 ${ROOT}/${CODE_FOLDER}/draco/nifi_volume
ssh ${USER}@${DRACO_IP} docker-compose -f ${ROOT}/${CODE_FOLDER}/docker-compose-draco.yml up --build &>/dev/null &
./supportScripts/wait-for-it.sh ${DRACO_IP}:${DRACO_API_PORT} --timeout=480 -- echo "draco is up"
echo "setup draco on ${DRACO_IP} complete"

ssh ${USER}@${FIWARE_IP} ${ROOT}/${CODE_FOLDER}/supportScripts/createIndexMongo.sh


echo "setup subscriptions"
#una sottoscrizione viene già creata dallo script di setup
echo "Begin create subscriptions"
for ((i=0; i<${SUB_NUM}; i++))
do
  echo "sub ${i}"
  curl -iX POST \
    --url "http://${FIWARE_IP}:${ORION_PORT_EXT}/v2/subscriptions" \
    --header 'Content-Type: application/json' \
    --header 'fiware-service: openiot' \
    --header 'fiware-servicepath: /' \
    --data '{
    "description": "Notify me when any Device changes state",
    "subject": {
    "entities": [{"idPattern": ".*","type": "Device"}],
    "condition": {
      "attrs": ["Status", "Payload", "Time"]
    }
    },
    "notification": {
    "http": {
      "url": "'"http://${DRACO_IP}:${DRACO_WS_PORT}/v2/notify"'"
    },
    "attrsFormat" : "keyValues"
    }
  }'
done
echo "Finish subscriptions creation"

echo "launch remote device on ${DEVICE_IP}"
ssh ${USER}@${KAFKACONSUMER_IP} mkdir -p ${ROOT}/${CODE_FOLDER}/devices/simpleDevice/mylogs
ssh ${USER}@${DEVICE_IP} "cd ${ROOT}/${CODE_FOLDER}/ && ./supportScripts/createDevices.sh ${FIRST_ID} ${NUM_DEVICE} ${DEVICE_TIME} ${HOW_MANY_MESSAGES} ${HOW_OFTEN_SPEEDUP} ${SPEEDUP} ${PAYLOAD_BYTE} ${EXP_NAME}"
echo "wait launch on ${DEVICE_IP} completion"
count_device=$(($(ssh ${USER}@${DEVICE_IP} "docker ps | grep device | wc -l")))
while [ "${count_device}" != "${NUM_DEVICE}" ]
do
  count_device=$(($(ssh ${USER}@${DEVICE_IP} "docker ps | grep device | wc -l")))
  sleep 10s
  echo "${count_device}/${NUM_DEVICE} device created"
done
echo "launch on ${DEVICE_IP} complete"

echo "turn on all the devices"
#dare on  a tutti i device, on deve essere mandato ad OCB
for ((i=${FIRST_ID}; i<${FIRST_ID}+${NUM_DEVICE}; i++))
do
  echo ${i}
  curl \
    --max-time 10 \
    --connect-timeout 2 \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 40 \
    -iX PATCH \
    --url "http://${FIWARE_IP}:${ORION_PORT_EXT}/v2/entities/urn:ngsi-ld:device:${i}/attrs" \
    --header 'Content-Type: application/json' \
    --header 'fiware-service: openiot' \
    --header 'fiware-servicepath: /' \
    --data '{
      "on": {
        "type": "command",
        "value": ""
      }
  }'
  #sleep 1s
done

sleep 20s

echo "wait completion"
count_device=$(($(ssh ${USER}@${DEVICE_IP} "docker ps | grep device | wc -l")))
while [ "${count_device}" != "0" ]
do
  count_device=$(($(ssh ${USER}@${DEVICE_IP} "docker ps | grep device | wc -l")))
  sleep 10s
done
echo "completed"

echo "wait before stop"
sleep 5m


#./supportScripts/stopAll.sh


echo "Begin download files"

mkdir -p ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}
mkdir -p ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}/"devices"
mkdir -p ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}/"consumer"

echo "download device data"
echo ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}/"devices"/
scp ${USER}@${DEVICE_IP}:${ROOT}/${CODE_FOLDER}/devices/simpleDevice/mylogs/${EXP_NAME}/*.csv ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}/"devices"/

echo "download consumer data"
ssh ${USER}@${KAFKACONSUMER_IP} "ls -1t ${ROOT}/${CODE_FOLDER}/pykafkaConsumer/mylogs/*.csv | head -1 | xargs -I{} mv {} ${ROOT}/${CODE_FOLDER}/pykafkaConsumer/mylogs/${EXP_NAME}.csv"
scp ${USER}@${KAFKACONSUMER_IP}:${ROOT}/${CODE_FOLDER}/pykafkaConsumer/mylogs/${EXP_NAME}.csv ${DATA_FOLDER}/${GROUP_EXP}/${EXP_NAME}/consumer/
echo "download done"
