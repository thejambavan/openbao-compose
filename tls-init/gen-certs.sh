#!/bin/sh
apk add openssl bash
set -e

CERT_DIR=/openbao/tls
mkdir -p "$CERT_DIR"
NODES="secrets01 secrets02 secrets03 haproxy"
SAN_ENTRIES="
DNS.1 = localhost
DNS.2 = secrets01
DNS.3 = secrets02
DNS.4 = secrets03
IP.1 = 127.0.0.1
"

# CA
if [ ! -f "$CERT_DIR/ca.pem" ]; then
  openssl genrsa -out "$CERT_DIR/ca-key.pem" 2048
  openssl req -x509 -new -nodes -key "$CERT_DIR/ca-key.pem" -sha256 -days 3650 \
    -out "$CERT_DIR/ca.pem" -subj "/CN=openbao-ca"
fi

for CN in $NODES; do
  if [ ! -f "$CERT_DIR/${CN}.pem" ]; then
    echo "[*] Generating cert for $CN..."

    cat > "$CERT_DIR/san.cnf" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
subjectAltName = @alt_names
[alt_names]
$SAN_ENTRIES
EOF

    openssl req -newkey rsa:2048 -nodes -keyout "$CERT_DIR/${CN}-key.pem" \
      -out "$CERT_DIR/${CN}.csr" -subj "/CN=${CN}" -config "$CERT_DIR/san.cnf"
    openssl x509 -req -in "$CERT_DIR/${CN}.csr" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" \
      -CAcreateserial -out "$CERT_DIR/${CN}.pem" -days 365 -sha256 -extensions v3_req \
      -extfile "$CERT_DIR/san.cnf"
  fi
  cat "$CERT_DIR/${CN}.pem" "$CERT_DIR/ca.pem" > "$CERT_DIR/${CN}-fullchain.pem"
done

# Bundle HAProxy PEM
cat "$CERT_DIR/haproxy.pem" "$CERT_DIR/haproxy-key.pem" > "$CERT_DIR/haproxy-combined.pem"
chown -R 100:1000 "$CERT_DIR"
