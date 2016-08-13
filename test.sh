#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200

source vault.token

#vault_bin=`realpath \`find ./ -iname vault -type f\``
vault_bin=`which vault`


#$vault_bin path-help secret

echo "Operating via CLI API:"
$vault_bin write secret/foo value=bar
$vault_bin read secret/foo


echo "Operating via HTTP API:"
curl \
    -H "X-Vault-Token: $vault_token" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"value":"bongo"}' \
    $VAULT_ADDR/v1/secret/mongo

curl \
    -H "X-Vault-Token: $vault_token" \
    -X GET \
    $VAULT_ADDR/v1/secret/mongo
