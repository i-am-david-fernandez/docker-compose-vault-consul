#!/bin/bash

set -e

vault_config="site/vault.cfg"
token_config="site/tokens.cfg"

echo "Removing existing containers and config..."
rm -f $vault_config
rm -f $token_config
docker-compose kill
docker-compose rm --force

echo "Removing existing data..."
sudo rm -rf data
mkdir -p data/consul
chmod ugo+rwX data/consul

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
        echo "vault_container=$vault_container" >> $vault_config
    fi
done
IFS=$IFS_org

vault_container_port="8200"
vault_host_port=`docker-compose ps | grep $vault_container | sed -e "s/.*:\\(.*\\)->$vault_container_port.*/\\1/g"`
vault_host_addr="http://127.0.0.1:$vault_host_port"
echo "vault_host_addr=$vault_host_addr" >> $vault_config

#vault_bin=`which vault`
vault_bin="docker run -e VAULT_ADDR=http://vault:$vault_container_port --link=${vault_container}:vault --rm vault"
echo "vault_bin=\"$vault_bin\"" >> $vault_config

## Wait for services to settle
echo "Waiting for services to settle..."
docker-compose logs
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
        echo "vault_unseal_key_$i=$key" >> $vault_config
    elif [[ $line =~ $pattern_token ]]
    then
        vault_root_token="${BASH_REMATCH[1]}"
        echo "Token: [$vault_root_token]"
        echo "vault_root_token=$vault_root_token" >> $vault_config
    fi
done
IFS=$IFS_org

## Unseal the vault
for key in $vault_unseal_keys
do
    $vault_bin unseal $key
done
