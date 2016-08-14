#!/bin/bash

source vault.cfg

echo "Operating via CLI API:"
vault auth $vault_root_token
vault write secret/foo value=bar
vault read secret/foo

echo "Operating via HTTP API:"
curl \
    -H "X-Vault-Token: $vault_root_token" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"value":"bongo"}' \
    $VAULT_ADDR/v1/secret/mongo

curl \
    -H "X-Vault-Token: $vault_root_token" \
    -X GET \
    $VAULT_ADDR/v1/secret/mongo
