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
from parse import parse

import pushover

WHAT_R_WE_DOIN            = "notify"
WAIT_HOW_LONG             = 3
WHERE_IS_ZMQ              = "tcp://127.0.0.1:5000"
WHAT_IS_OUR_NAME          = "JoshAshby"
WHAT_CHANNELS_WE_WANT_BRO = ["#it"]

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect (WHERE_IS_ZMQ)
socket.setsockopt(zmq.SUBSCRIBE, 'irssi')


channel_bucket = {}

message_format = "irssi [{type}][{away_status:d}][{channel}][{nick}]{message}"


def publish_pushover(data):
    data["timestamp"] = data["timestamp"].timestamp

    try:
        pushover.pushover(**data)
    except Exception as e:
        print e


def publish_notify(data):
    alert = "%s @ %s\n%s" % (data["title"],
                             data["timestamp"].humanize(),
                             data["message"])
    subprocess.Popen(['notify-send', alert])


def listen_blocking():
    while True:
        try:
            raw = socket.recv()
            parsed_data = parse(message_format, raw).named

            if ((parsed_data["type"] == "private" or WHAT_IS_OUR_NAME in\
              parsed_data["message"]) and parsed_data["away_status"]) or\
              parsed_data["channel"] in WHAT_CHANNELS_WE_WANT_BRO:
                time = arrow.utcnow()

                if parsed_data["channel"] in channel_bucket:
                    channel_bucket[parsed_data["channel"]] += 1
                else:
                    channel_bucket[parsed_data["channel"]] = 1

                local_data = {
                    "timestamp": time,
                    "title":     parsed_data["nick"][:20],
                    "message":   parsed_data["message"][:479]
                    }


                if WHAT_R_WE_DOIN == "notify":
                    publish_notify(local_data)

                elif WHAT_R_WE_DOIN == "pushover":
                    if channel_bucket[parsed_data["channel"]] >= WAIT_HOW_LONG:
                        channel_bucket[parsed_data["channel"]] = 0
                        publish_pushover(local_data)

        except AttributeError:
            pass

        except KeyboardInterrupt:
            break;


if __name__ == "__main__":
    listen_blocking()
