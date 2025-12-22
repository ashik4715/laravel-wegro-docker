#!/bin/bash
# Script to copy Let's Encrypt certificates to the format expected by nginx-proxy
# This is optional - the custom config uses /etc/letsencrypt directly, but this helps with compatibility

set -e

CERT_DIR="/etc/letsencrypt/live/callcircle.resilentsolutions.com"
LOCAL_CERTS_DIR="./certs"
DOMAIN="callcircle.resilentsolutions.com"

echo "Setting up certificates for $DOMAIN..."

# Create local certs directory if it doesn't exist
mkdir -p "$LOCAL_CERTS_DIR"

# Copy certificates with nginx-proxy expected naming
if [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "Copying fullchain.pem to $LOCAL_CERTS_DIR/$DOMAIN.crt"
    sudo cp "$CERT_DIR/fullchain.pem" "$LOCAL_CERTS_DIR/$DOMAIN.crt"
    sudo chmod 644 "$LOCAL_CERTS_DIR/$DOMAIN.crt"
else
    echo "ERROR: Certificate file not found at $CERT_DIR/fullchain.pem"
    exit 1
fi

if [ -f "$CERT_DIR/privkey.pem" ]; then
    echo "Copying privkey.pem to $LOCAL_CERTS_DIR/$DOMAIN.key"
    sudo cp "$CERT_DIR/privkey.pem" "$LOCAL_CERTS_DIR/$DOMAIN.key"
    sudo chmod 600 "$LOCAL_CERTS_DIR/$DOMAIN.key"
else
    echo "ERROR: Private key file not found at $CERT_DIR/privkey.pem"
    exit 1
fi

echo "Certificates copied successfully!"
echo "You can now restart the proxy-server container:"
echo "  docker compose up -d proxy-server"


