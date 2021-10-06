'use strict';
/*
  In tutti i punti in cui comunico con fiware trasmettere anche il timestamp riferito all'invio del messaggio

*/

const mqtt = require('mqtt')
const fs = require('fs')
require("dotenv").config()

const ID = process.env.ID
const KEY = process.env.API_KEY || "4jggokgpepnvsb2uv4s40d59ov"
const MOSQUITTO = process.env.MOSQUITTO || "mqtt://mosquitto"
const MOSQUITTO_PORT = process.env.MOSQUITTO_PORT || 1883
var isEnabled = process.env.STATUS == "on"
var TIME = process.env.TIME || 1000
const EXP_NAME = process.env.EXP_NAME || "default"
const HOW_MANY = process.env.HOW_MANY || 1000
const HOW_OFTEN = process.env.HOW_OFTEN || 1000
const STEP=process.env.STEP || 100
const PAYLOAD_BYTE = process.env.PAYLOAD_BYTE || 0

function randomString(length) {
  const chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  var result = '';
  for (var i = length; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
  return result;
}

const payload = randomString(PAYLOAD_BYTE)

var counter = 0
var counter_step = 0
var measurer = null

const path = `/tmp/test/mylogs/${EXP_NAME}`
if (!fs.existsSync(path)){
  fs.mkdirSync(path);
}
var stream = fs.createWriteStream(`${path}/term${ID}.csv`, {flags: 'a'})
let date = new Date()

console.log(`device${ID}: bootup, isEnabled=${isEnabled}`)
console.log(`${MOSQUITTO}:${MOSQUITTO_PORT}`)
console.log(`${PAYLOAD_BYTE}`)
//stream.write(`${(date.toISOString())}, ${date.getTime()}, device${ID}, null\n`)
stream.write(`device${ID},${isEnabled},${date.getTime()}\n`)

var client  = mqtt.connect(`${MOSQUITTO}`, {
  port: MOSQUITTO_PORT
})

function publishStatus() {
  client.publish(`/${KEY}/device${ID}/attrs`, `{"s": ${isEnabled}}`)
}

function publishCommandStatus(command, status) {
  client.publish(`/${KEY}/device${ID}/cmdexe`, `{"${command}": "${status}"}`)
}

function registerMeasuerer(){
  measurer = setInterval(measure, TIME)
}

function deRegisterMeasurer(){
  clearInterval(measurer)
}

function getMillis(){
  let date = new Date()
  return date.getTime()
}

function measure(){
  if (isEnabled) {
    let date = new Date()
    //stream.write(`${(date.toISOString())}, ${date.getTime()}, device${ID}\n`)
    stream.write(`device${ID},${isEnabled},${date.getTime()}\n`)
    client.publish(`/${KEY}/device${ID}/attrs`, `{"p": "${payload}", "s":${isEnabled}, "time":${date.getTime()}}`)
    //console.log(`device${ID}: ${counter}/${HOW_MANY}, this step: ${counter_step}/${HOW_OFTEN})`)
    counter++
    counter_step++
    if (counter >= HOW_MANY) {
      process.exit(0)
    }
    if (HOW_OFTEN!=0 && counter_step >= HOW_OFTEN && TIME > 0){
      deRegisterMeasurer()
      TIME -= STEP
      if (TIME == 0) {TIME=1}
      counter_step = 0
      registerMeasuerer()
      console.log(`device${ID}: increasedFreq, new=${TIME}`)
    }
  } else {
    //console.log(`device${ID}: disabled`)
  }
}


client.on("connect", function() {
  console.log(`[device${ID}]: connection enstablished`)
  /**
   * Tells fiware if i'm already on or not
   */
  publishStatus()
  /**
   * fiware will publish commands on this topic
   */
  client.subscribe(`/${KEY}/device${ID}/cmd`)
})


/**
 * Hadles messages recevied from the broker
 */
client.on('message', function (topic, message) {
  console.log(`topic: ${topic.toString()}`)
  console.log(`message: ${message.toString()}`)
  let command = Object.keys(JSON.parse(message))[0]
  switch (command) {
    case "on":
      isEnabled = true
      registerMeasuerer()
      publishStatus()
      console.log(`device[${ID}] turned on`)
      client.publish(`/${KEY}/device${ID}/cmdexe`, `{"on": "ok"}`)
      break;

    case "off":
      isEnabled = false
      deRegisterMeasurer()
      client.publish(`/${KEY}/device${ID}/attrs`, `{"s": ${isEnabled}, "time":${getMillis()}}`)
      client.publish(`/${KEY}/device${ID}/cmdexe`, `{"off": "ok"}`)
      break;

    case "stop":
      stream.end()
  }
})
