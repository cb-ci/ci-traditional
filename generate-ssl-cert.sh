#!/bin/bash

set -e

current_dir=$(pwd)
SSL_DIR="./ssl"
mkdir -p $SSL_DIR
cd $SSL_DIR
CERT_FILE="server.crt"
KEY_FILE="server.key"
STORE_PW="changeit"

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is not set. Set JAVA_HOME first"
  exit 1
else
  echo "JAVA_HOME is set to: $JAVA_HOME"
fi


if command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is installed."
else
  echo "OpenSSL is not installed."
  exit 1
fi



echo "=== SSL Certificate Generation Script ==="

# Check if certificates already exist
if [[ -f "${CERT_FILE}" && -f "${KEY_FILE}" ]]; then
    echo "✓ SSL certificates already exist:"
    echo "  - ${CERT_FILE}"
    echo "  - ${KEY_FILE}"
    echo ""
    read -p "Do you want to regenerate them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping certificate generation."
        exit 0
    fi
fi

echo "Generating self-signed SSL certificate..."

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=DevOps/CN=localhost" \
    -addext "subjectAltName=DNS.1:localhost,DNS.2:nginx,DNS.3:jenexus,IP:127.0.0.1,IP:172.20.0.11"

# Set appropriate permissions
chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

echo ""
echo "✓ SSL certificate generated successfully:"
echo "  - Certificate: ${CERT_FILE}"
echo "  - Private Key: ${KEY_FILE}"
echo ""
echo "⚠️  Note: This is a self-signed certificate. Browsers will show security warnings."
echo "   For production use, replace with a certificate from a trusted CA."

# copy cacerts from JAVA_HOME
cp -f -v $JAVA_HOME/lib/security/cacerts .

## Create a Java KeyStore (JKS) to hold the key, and delete the default jenkins alias
keytool -genkey -alias jenkins -keystore jenkins.jks -keyalg rsa -storepass $STORE_PW -keypass $STORE_PW

# choose blank values, and for question "Is CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown correct?" answer "yes", as we are deleting this one
keytool -delete -alias jenkins -keystore jenkins.jks -storepass $STORE_PW -keypass $STORE_PW

## Convert PEM and add it to the jenkins.jks (Java KeyStore)
openssl pkcs12 -export -in ${CERT_FILE} -inkey ${KEY_FILE} -out jenkins.p12 -name jenkins -CAfile ${CERT_FILE} -caname root -passout pass:$STORE_PW

# enter a password when prompted, for example 'changeit'
keytool -importkeystore -destkeystore jenkins.jks -srckeystore jenkins.p12 -srcstoretype PKCS12 -storepass $STORE_PW -keypass $STORE_PW -alias jenkins
# enter the same password when prompted, for example 'changeit'

# Now you have a jenkins.jks that can be used for TLS on each replica

# create pem file, includes private key and certificate
# PEM  will be referenced by jenkins and by the patched cacerts
cat ${CERT_FILE} ${KEY_FILE} > jenkins.pem

# Add the pem file to the cacerts
#keytool -delete -noprompt -alias jenkins -keystore cacerts -storepass $STORE_PW
keytool -import -noprompt -keystore cacerts -file jenkins.pem -storepass $STORE_PW -keypass $STORE_PW -alias jenkins

cd $current_dir
