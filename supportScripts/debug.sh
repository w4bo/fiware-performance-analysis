#!/bin/bash
SET_ID="debugv0"

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

rm ${LOG_FILE}
touch ${LOG_FILE}
mkdir -p ${DATA_FOLDER}/${SET_ID}

./supportScripts/launchRemoteExperiment.sh 2 200 1 10 0 0 1000 "debug_${SET_ID}" ${SET_ID}

mv ${DATA_FOLDER}/*_${SET_ID} ${DATA_FOLDER}/${SET_ID}

./supportScripts/downloadMissing.sh ${LOG_FILE}
#./supportScripts/stopAll.sh
#./supportScripts/removeRemoteLogs.sh
