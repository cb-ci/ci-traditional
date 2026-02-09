#!/bin/bash
set -e

source .env

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi

if [[ ! -f "./ssl/server.crt" || ! -f "./ssl/server.key" ]]; then
  ./generate-ssl-cert.sh
else
  echo "SSL certificates already exist. Run 'rm -Rf ssl/*' to recreate them"
fi
./down.sh
envsubst < haproxy-config/haproxy-ssl.cfg > "${HA_PROXY_CONFIG}"


docker-compose  up -d --build

#open http://127.0.0.1:6080

docker-compose logs -f 