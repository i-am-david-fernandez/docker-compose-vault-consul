#!/bin/bash

set -e

vault_config="site/vault.cfg"
source $vault_config

export VAULT_ADDR=$vault_host_addr

## Unseal the vault
for i in `seq 1 3`
do
    key=vault_unseal_key_$i
    vault unseal "${!key}"
done
