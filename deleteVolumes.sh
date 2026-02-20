#!/bin/bash

source .env

./down.sh
rm -rf ${LOCAL_VOLUME}
# rm -rf ssl
# docker volume ls -q |xargs  docker volume rm

