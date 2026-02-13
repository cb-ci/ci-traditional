#!/bin/bash

set -e

current_dir=$(pwd)
SSL_DIR="./ssl"
mkdir -p $SSL_DIR
cd $SSL_DIR
CERT_FILE="server.crt"
KEY_FILE="server.key"
STORE_PW="changeit"

# Ensure variables are set or have defaults for the -subj flag
CJOC_HOST=${CJOC_HOST:-"localhost"}
CONTROLELR_HOST=${CONTROLELR_HOST:-"controller.local"}
CONTROLLER_IP=${CONTROLLER_IP:-"127.0.0.1"}
CJOC_IP=${CJOC_IP:-"127.0.0.1"}

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is not installed."
  exit 1
fi

echo "=== SSL Certificate Generation Script (Automated) ==="

if [[ -f "${CERT_FILE}" && -f "${KEY_FILE}" ]]; then
    echo "✓ SSL certificates exist. Overwriting for automation..."
fi

echo "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=DevOps/CN=${CJOC_HOST}" \
    -addext "subjectAltName=DNS.1:${CJOC_HOST},DNS.2:${CONTROLELR_HOST},DNS.3:localhost,IP:127.0.0.1,IP:${CONTROLLER_IP},IP:${CJOC_IP}"

chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

# Copy cacerts
cp -f $JAVA_HOME/lib/security/cacerts .
# Create the pem , ${KEY_FILE} is the private key and ${CERT_FILE} is the public key.
# ${KEY_FILE} should not be required in cacert truststore (just the public key is required), but it doesn't hurt to have it for the demo
cat "${CERT_FILE}" "${KEY_FILE}" > jenkins.pem

# Final Import: -noprompt ensures it doesn't ask "Trust this certificate?"
keytool -import -noprompt -keystore cacerts -file jenkins.pem \
    -storepass "$STORE_PW" -alias jenkins

cd "$current_dir"
echo "Done."