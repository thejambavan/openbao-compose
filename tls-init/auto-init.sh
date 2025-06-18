#!/bin/sh
set -e
apk add curl jq

VAULT_ADDR=https://$1:8200
OPENBAO_ADDR=https://$1:8200
CERTS=/openbao/tls

export VAULT_ADDR
export VAULT_CACERT=$CERTS/ca.pem

export OPENBAO_ADDR
export OPENBAO_CACERT=$CERTS/ca.pem

# Wait for OpenBao to be reachable
until curl -s --cacert "$CERTS/ca.pem" "$VAULT_ADDR/v1/sys/health" | grep -q 'initialized'; do
  echo "[*] Waiting for OpenBao API at $VAULT_ADDR..."
  sleep 2
done

STATUS=$(curl -s --cacert "$CERTS/ca.pem" "$VAULT_ADDR/v1/sys/health")

if echo "$STATUS" | grep -q '"initialized":false'; then
  echo "[*] Initialising OpenBao..."
  INIT=$(vault operator init -format=json -key-shares=1 -key-threshold=1)
  echo "$INIT" > "$CERTS/init.json"
  bao operator unseal "$(echo "$INIT" | jq -r .unseal_keys_b64[0])"
else
  echo "[*] OpenBao already initialised"
  if [ -f "$CERTS/init.json" ]; then
    KEY=$(jq -r .unseal_keys_b64[0] "$CERTS/init.json")
    bao operator unseal "$KEY" || true
  fi
fi

