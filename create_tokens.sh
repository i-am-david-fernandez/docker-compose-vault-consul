#!/bin/bash

vault_config="site/vault.cfg"
token_config="site/tokens.cfg"

source $vault_config

export VAULT_ADDR=$vault_host_addr

echo $*

if which vault > /dev/null
then
    echo "Operating via CLI API."
    vault auth $vault_root_token

    for token_name in $*
    do
        ## Create a non-root token
        echo "Creating a token with display name $token_name"
        pattern_token="token.*"

        lines=`vault token-create -display-name=$token_name`
        IFS_org=$IFS
        IFS=$'\n'
        for line in $lines
        do
            echo $line
            if  [[ $line =~ $pattern_token ]]
            then
                label=`echo $line | awk '{ print $1 }'`
                value=`echo $line | awk '{ print $2 }'`
                echo "${token_name}_$label=\"$value\"" >> $token_config
            fi

        done
        IFS=$IFS_org
    done
else
    echo "Vault CLI binary not found. Cannot operate via CLI API."
fi

