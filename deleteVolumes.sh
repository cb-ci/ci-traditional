#!/bin/bash

source .env

./down.sh
rm -rf ${LOCAL_VOLUME}
docker volume ls -q |xargs  docker volume rm

