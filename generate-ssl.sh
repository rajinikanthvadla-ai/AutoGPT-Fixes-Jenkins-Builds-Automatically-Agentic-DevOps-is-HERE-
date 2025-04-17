#!/bin/bash

# Create SSL directory
mkdir -p ssl
cd ssl

# Generate private key
openssl genrsa -out server.key 2048

# Generate CSR
openssl req -new -key server.key -out server.csr -subj "/CN=localhost"

# Generate self-signed certificate
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# Set proper permissions
chmod 600 server.key
chmod 644 server.crt

echo "SSL certificates generated successfully!"
echo "Certificate: $(pwd)/server.crt"
echo "Private key: $(pwd)/server.key" 