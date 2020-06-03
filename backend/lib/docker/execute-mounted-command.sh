#!/bin/bash

echo "Executing mounted command."

if [[ ! -z "$AFTER_CONTAINER_DID_MOUNT" ]]; then
  echo "AFTER_CONTAINER_DID_MOUNT: $AFTER_CONTAINER_DID_MOUNT"
  sh -c "$AFTER_CONTAINER_DID_MOUNT"
else
	echo "Warning: AFTER_CONTAINER_DID_MOUNT is not set."
fi
eval $@