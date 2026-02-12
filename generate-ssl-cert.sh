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
CJOC_URL=${CJOC_URL:-"localhost"}
CONTROLLER_URL=${CONTROLLER_URL:-"controller.local"}
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

# 1. Automatic Regeneration: No more read -p prompt
if [[ -f "${CERT_FILE}" && -f "${KEY_FILE}" ]]; then
    echo "✓ SSL certificates exist. Overwriting for automation..."
fi

echo "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=DevOps/CN=${CJOC_URL}" \
    -addext "subjectAltName=DNS.1:${CJOC_URL},DNS.2:${CONTROLLER_URL},DNS.3:localhost,IP:127.0.0.1,IP:${CONTROLLER_IP},IP:${CJOC_IP}"

chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

# Copy cacerts
cp -f $JAVA_HOME/lib/security/cacerts .


# 3. PKCS12 Conversion: Passwords handled via -passout and -passin
openssl pkcs12 -export -in "${CERT_FILE}" -inkey "${KEY_FILE}" \
    -out jenkins.p12 -name jenkins -CAfile "${CERT_FILE}" -caname root \
    -passout pass:"$STORE_PW"

cat "${CERT_FILE}" "${KEY_FILE}" > jenkins.pem

# 5. Final Import: -noprompt ensures it doesn't ask "Trust this certificate?"
keytool -import -noprompt -keystore cacerts -file jenkins.pem \
    -storepass "$STORE_PW" -alias jenkins

cd "$current_dir"
echo "Done."