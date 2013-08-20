"""
Basic util to work with zeromq.pl to listen for irssi events on a ZeroMQ
PUB/SUB channel and display a notification, or publish a notification to
pushover.

Joshua Ashby - 2013
https://github.com/JoshAshby/irssi-utils

Licensed under the CC BY-NC-SA 3.0
  http://creativecommons.org/licenses/by-nc-sa/3.0/
"""
import zmq
import subprocess
import arrow

import pushover

WHAT_R_WE_DOIN = "notify"
WAIT_HOW_LONG  = 5
WHERE_IS_ZMQ   = "tcp://127.0.0.1:5000"

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect (WHERE_IS_ZMQ)
socket.setsockopt(zmq.SUBSCRIBE, 'irssi')


channel_bucket = {}


def publish_pushover(data):
    data["date"] = data["date"].timestamp

    try:
      pushover.pushover(**data)


def publish_notify(data):
    alert = "%s @ %s\n%s" % (data["title"],
                             data["time"].humanize(),
                             data["message"])
    subprocess.Popen(['notify-send', alert])


def listen():
    channel, message = socket.recv().split(' ', 1)[1].split(' ', 1)
    print channel

    time = arrow.utcnow()

    if channel in channel_bucket:
        channel_bucket[channel] += 1
    else:
        channel_bucket[channel] = 1


    local_data = {
        "message": message,
        "title":   channel,
        "date":    time
    }

    if WHAT_R_WE_DOIN == "notify":
        publish_notify(local_data)

    else:
        if channel_bucket[channel] >= WAIT_HOW_LONG:
            channel_bucket[channel] = 0
            publish_pushover(local_data)


if __name__ == "__main__":
    while True:
        listen()
