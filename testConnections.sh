#! /bin/bash
set -e
set -x
source .env

TOKEN=$(cat data/jenkins-home-oc/cjoc_token.txt)
export TOKEN="${CJOC_LOGIN_USER}:${TOKEN}"
CJOC_URL="https://${CJOC_HOST}"
curl -u $TOKEN -I -N \
     -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Host: ${CJOC_HOST}" \
     -H "Origin: ${CJOC_URL}" \
     -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     -H "Sec-WebSocket-Version: 13" \
     ${CJOC_URL} 2>&1

curl -u $TOKEN -I -D -o response.txt \
     -H "Host: ${CJOC_HOST}" \
     -H "Origin: ${CJOC_URL}" \
     ${CJOC_URL} 2>&1