#!/bin/bash
set -e

source .env

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Docker Compose not found. Install Docker Compose v2 ('docker compose') or v1 ('docker-compose')."
  exit 127
fi

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi

if [[ ! -f "./license.crt" || ! -f "./license.key" ]]; then
  echo "CloudBees CI license files './license.crt' './license.key' not found. Create them or copy them to the current directory"
  exit 1
fi



if [[ ! -f "./ssl/server.crt" || ! -f "./ssl/server.key" || ! -f "./ssl/jenkins.pem" || ! -f "./ssl/cacerts" ]]; then
  ./generate-ssl-cert.sh
else
  echo "SSL certificates already exist. Run 'rm -Rf ssl/*' to recreate them"
fi
./down.sh

# Create HAProxy config from template
envsubst < haproxy-config/haproxy-ssl.cfg > "${HA_PROXY_CONFIG}"

# workaround to avoid https://github.com/testcontainers/testcontainers-java/issues/11222
mkdir -p "${CJOC_PERSISTENCE}"
cp -f ./license.crt "${CJOC_PERSISTENCE}/license.crt"
cp -f ./license.key "${CJOC_PERSISTENCE}/license.key"
chmod 600 "${CJOC_PERSISTENCE}/license.crt" "${CJOC_PERSISTENCE}/license.key"
echo "Copied license files to ${CJOC_PERSISTENCE}"

mkdir -p "${CJOC_PERSISTENCE}/init.groovy.d"
cp -f ./jenkins_init.groovy.d/init_user.groovy "${CJOC_PERSISTENCE}/init.groovy.d/init_user.groovy"
chmod 644 "${CJOC_PERSISTENCE}/init.groovy.d/init_user.groovy"
echo "Copied init_user.groovy to ${CJOC_PERSISTENCE}/init.groovy.d"
# sudo chown -R 1000:1000 ${CJOC_PERSISTENCE} ${CONTROLLER_PERSISTENCE} 

# End workaround

mkdir -p "${CONTROLLER_PERSISTENCE}"

# Start the services
"${COMPOSE_CMD[@]}" up -d --build

#open https://cjoc.local
#open https://controller.local

#"${COMPOSE_CMD[@]}" logs -f

# TOKEN=$(cat data/jenkins-home-oc/cjoc_token.txt)
# export TOKEN="${CJOC_LOGIN_USER}:${TOKEN}"
# echo $TOKEN
# BASE=administrativeMonitor/hudson.diagnosis.ReverseProxySetupMonitor
# curl -u "$TOKEN" -iL -X POST "https://${CJOC_HOST}/jenkins/${BASE}/test"


# curl -u "$TOKEN" -v https://${CJOC_HOST}/ 2>&1 | grep -E '< (Location|Set-Cookie|X-)'
