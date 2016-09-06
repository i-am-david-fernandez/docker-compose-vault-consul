#!/bin/bash

source vault.cfg

export VAULT_ADDR=$vault_host_addr

if which vault > /dev/null
then
    echo "Operating via CLI API:"
    vault auth $vault_root_token
    vault write secret/foo value=bar
    vault read secret/foo
else
    echo "Vault CLI binary not found. Cannot test via CLI API."
fi

if which curl > /dev/null
then
    echo "Operating via HTTP API:"
    curl \
        -H "X-Vault-Token: $vault_root_token" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"value":"bongo"}' \
        $vault_host_addr/v1/secret/mongo

    curl \
        -H "X-Vault-Token: $vault_root_token" \
        -X GET \
        $vault_host_addr/v1/secret/mongo
else
    echo "Curl binary not found; cannot test via HTTP API."
fi
