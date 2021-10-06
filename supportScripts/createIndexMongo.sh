#!/bin/bash

docker exec mongo-db-orion mongo --eval '
    conn = new Mongo();
    db = conn.getDB("iotagentjson");
    db.createCollection("devices");
    db.devices.createIndex({"_id.service": 1, "_id.id": 1, "_id.type": 1});
    db.devices.createIndex({"_id.type": 1});
    db.devices.createIndex({"_id.id": 1});
    db.createCollection("groups");
    db.groups.createIndex({"_id.resource": 1, "_id.apikey": 1, "_id.service": 1});
    db.groups.createIndex({"_id.type": 1});' > /dev/null
