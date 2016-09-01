#!/bin/bash

set -e

echo "Removing existing containers and config..."
rm -f vault.cfg
docker-compose kill
docker-compose rm --force

vault_port="8200"
vault_addr="http://127.0.0.1:$vault_port"

echo "Creating new containers..."
pattern_vault="Creating (.*_vault_[0-9]*)"
IFS_org=$IFS
IFS=$'\n'
for line in `docker-compose up -d 2>&1`
do
    echo "$line"
    if [[ $line =~ $pattern_vault ]]
    then
        vault_container="${BASH_REMATCH[1]}"
        echo "vault_container=$vault_container" >> vault.cfg
    fi
done
IFS=$IFS_org

#vault_bin=`which vault`
vault_bin="docker run -e VAULT_ADDR=http://vault:$vault_port --link=${vault_container}:vault --rm vault"
echo "vault_bin=\"$vault_bin\"" >> vault.cfg

## Wait for services to settle
echo "Waiting for services to settle..."
sleep 4

vault_unseal_keys=""
vault_root_token=""

## Initialise the vault, capturing output for processing
lines=`$vault_bin init`

## Extract unseal keys and root token from 'init' output
IFS_org=$IFS
IFS=$'\n'
for line in $lines
do
    echo $line

    ## We're looking for key and token lines like this:
    ## Unseal Key 1: 5ead4aecf092af1ffddb8ae4ec5156be7f27edd350b738782b6277d7aab578e501
    ## Initial Root Token: 23dce6f7-8ece-b165-6e5e-8d600cf920ae
    pattern_key="Unseal Key ([0-9]): (.*)"
    pattern_token="Initial Root Token: (.*)"

    if [[ $line =~ $pattern_key ]]
    then
        i="${BASH_REMATCH[1]}"
        key="${BASH_REMATCH[2]}"
        vault_unseal_keys="$vault_unseal_keys $key"
        echo "Key: [$key]"
        echo "vault_unseal_key_$i=$key" >> vault.cfg
    elif [[ $line =~ $pattern_token ]]
    then
        vault_root_token="${BASH_REMATCH[1]}"
        echo "Token: [$vault_root_token]"
        echo "vault_root_token=$vault_root_token" >> vault.cfg
    fi
done
IFS=$IFS_org

## Unseal the vault
for key in $vault_unseal_keys
do
    $vault_bin unseal $key
done
