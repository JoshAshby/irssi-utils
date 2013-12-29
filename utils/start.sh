#!/bin/bash

if [ -z "$STATE" ]; then
  export VIRTUAL_ENV_DISABLE_PROMPT='1'
  export STATE='true'

  source ./virt/normal/bin/activate

  export PUSHOVER_APP=wat
  export PUSHOVER_USER=wat
fi

python irssi-nofity.py
