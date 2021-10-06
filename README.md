# Setup

## env file
Edit the `.env` file and specify all the required parameters in the "ENV configuration" section.

- DRACO_IP: IP address of the machine that will execute Draco
- FIWARE_IP: IP address of the machine that will execute the Fiware ecosystem (OCB, IOTA, MQTT Broker, Kafka, Zookeeper)
- DEVICE_IP: IP address of the machine that will execute the devices
- KAFKACONSUMER: IP address of the machine that will execute the kafka consumer
- USER: which user will execute the experiment
- ROOT: home folder of the user
- CODE_FOLDER: repo location

Through the `.env` file it is also possible to modify the ports used by the various services and the topic used by kafka (KAFKA_TOPIC)

## Edit draco configuration

Use the following command to launch Draco in edit mode and edit the configuration for the `publish kafka record` block

```bash
docker-compose --file docker-compose-editnifi.yml up --build
```
Set:
- kafka brokers: samve value as "FIWARE_IP" in .evn
- topic name: same value as "KAFKA_TOPIC" in .env

Stop the executione before continue

## Build

```bash
./supportScripts/build.sh
```

## Note
- we assume that:
  - the repo is cloned in the same location across all the mechines involved in the experiment
  - ssh auth via public key is in place

# Execute experiments

```bash
./testScripts/executeAllOfficial.sh EXP_VERSION
```
This command will execute all the experiments, results will be saved in `DATA_FOLDER`, as specified in the `.env` file 

# Analysis

1. switch to the `analysis` folder
2. create the virtual env
```bash
python -m venv venv
source venv/Scripts/activate (On Windows git bash)
source venv/bin/activate (On Linux)
pip install -r requirements.txt
```
3. open the `graph_data.ipynb` notebook and specify the dataset (the datasets are located in the `data` folder)
4. Execute the jupyter notebook to generate the graphs.
