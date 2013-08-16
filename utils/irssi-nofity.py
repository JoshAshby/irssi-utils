"""
Basic quick utility to capture irssi messages sent over zeromq and queue them,
sending the latest one when the count for a channel is high enough
"""
import sys
import zmq
import requests
import arrow

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect ("tcp://127.0.0.1:5000")
socket.setsockopt(zmq.SUBSCRIBE, 'irssi')

pushover_api      = "https://api.pushover.net/1/messages.json"
pushover_user_key = "HuG1asKCjXHpNM45vSNzbxbGumjZcA"
pushover_app_key  = "Z8qU23R3Dm5Bnsgu9pEcPacAE9ctRq"
pushover_data     = {
    "token": pushover_app_key,
    "user": pushover_user_key,
    "message": ""
    }

channel_bucket = {}

while True:
    channel, message = socket.recv().split(' ', 1)[1].split(' ', 1)
    if channel in channel_bucket:
        channel_bucket[channel] += 1
    else:
        channel_bucket[channel] = 1

    local_data = pushover_data

    local_data["message"] = message
    local_data["title"]   = channel
    time = arrow.utcnow()
    local_data["date"]    = time.timestamp

    if channel_bucket[channel] >= 5:
        channel_bucket[channel] = 0

        result = requests.post(pushover_api, local_data)
        print result.json()
