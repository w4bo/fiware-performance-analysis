#!/bin/bash
if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi


FROM=$1
NUM=$2
TIME=$3
HOW_MANY=$4
HOW_OFTEN=$5
STEP=$6
PAYLOAD_KB=$7
EXP_NAME=$8

echo ${EXP_NAME}

#build image
echo $(pwd)
cd  ${ROOT}/${CODE_FOLDER}/devices/simpleDevice
docker build -t monte/device --build-arg uid=$(id -u) .

#sleep 1m

#start devices
for ((i=${FROM}; i<${FROM}+${NUM}; i++))
do
  echo ${i}
  ./launcher.sh ${i} off ${TIME} ${EXP_NAME} ${HOW_MANY} ${HOW_OFTEN} ${STEP} ${PAYLOAD_KB} &>/dev/null &
  sleep 0.5
done

