#!/bin/sh

echo "Setup CloudProxy and Mount Staging"

echo "> Setting up CloudProxy on $SANDBOX_ID for $PROXY_INSTANCE_NAME"
mkdir /tmp/csql
cloud_sql_proxy -dir /tmp/csql  --instances=$PROXY_INSTANCE_NAME &
echo "> Started Proxy – Waiting for it to boot"
sleep 4
echo "> Proxy Setup"

echo "> Mounting staging"
pwd
ls
cd ./backend
SANDBOX_ID=$SANDBOX_ID PROXY_INSTANCE_NAME=$PROXY_INSTANCE_NAME sh ./lib/docker/mount-cloud-proxy.sh

echo "> Mounting completed"