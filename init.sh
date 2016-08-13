#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200

#vault_bin=`realpath \`find ./ -iname vault -type f\``
vault_bin=`which vault`

#pushd ./vault-consul > /dev/null

docker-compose kill
docker-compose rm --force

#sudo rm -rf ./store

docker-compose up -d

sleep 8

#docker ps -a

rm -f vault.keys vault.token

IFS=$'\n'
for line in `$vault_bin init`
do
    echo $line
    ## Unseal Key 1: 5ead4aecf092af1ffddb8ae4ec5156be7f27edd350b738782b6277d7aab578e501
    ## Initial Root Token: 23dce6f7-8ece-b165-6e5e-8d600cf920ae

    pattern_key="Unseal Key ([0-9]): (.*)"
    pattern_token="Initial Root Token: (.*)"

    if [[ $line =~ $pattern_key ]]
    then
        i="${BASH_REMATCH[1]}"
        key="${BASH_REMATCH[2]}"
        echo "Key: [$key]"
        echo "vault_key_$i=$key" >> vault.keys

        $vault_bin unseal $key
    elif [[ $line =~ $pattern_token ]]
    then
        token="${BASH_REMATCH[1]}"
        echo "Token: [$token]"
        echo "vault_token=$token" > vault.token
        $vault_bin auth $token
    fi
done

#docker-compose kill
#docker-compose rm --force
