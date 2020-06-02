#!/bin/bash

echo "Loading server"

if [[ ! -z "$AFTER_CONTAINER_DID_MOUNT" ]]; then
  echo "> AFTER_CONTAINER_DID_MOUNT: $AFTER_CONTAINER_DID_MOUNT"
  sh -c "$AFTER_CONTAINER_DID_MOUNT"
fi

echo "> Mounted"

rails server -b 0.0.0.0 -p 8081