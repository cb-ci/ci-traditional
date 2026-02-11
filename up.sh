#!/bin/bash
set -e

source .env

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi

if [[ ! -f "./license.crt" || ! -f "./license.key" ]]; then
  echo "CloudBees CI license files not found. Create them or copy them to the current directory"
  exit 1
fi



if [[ ! -f "./ssl/server.crt" || ! -f "./ssl/server.key" ]]; then
  ./generate-ssl-cert.sh
else
  echo "SSL certificates already exist. Run 'rm -Rf ssl/*' to recreate them"
fi
./down.sh

# Create HAProxy config from template
envsubst < haproxy-config/haproxy-ssl.cfg > "${HA_PROXY_CONFIG}"

docker-compose  up -d --build

#open https://cjoc.local
#open https://controller.local

#docker-compose logs -f 
