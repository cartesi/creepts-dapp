#!/bin/sh

# account password
password='private_network'

# create a password file with a dummy password (this is just a test private network)
echo $password > passwd

# create two accounts
echo "Creating accounts"
geth account new --password passwd
geth account new --password passwd

# create a genesis.json (based on genesis.jq) with balance for all accounts generated above
echo "Creating genesis.json with balance for all created accounts"
jq -s '.' /root/.ethereum/keystore/* | jq '.[] | .address | {(.): { balance: "100000000000000000000000" }}' | jq -s add | jq -f genesis.jq > genesis.json

# distribute accounts and private keys to other nodes
echo "Distributing accounts and keys to nodes"

i=0
for filename in /root/.ethereum/keystore/*; do
    account_private_key=`web3 account extract --keyfile $filename --password $password`
    account=`echo "$account_private_key" | grep address | cut -d ' ' -f 3 | cut -c 3-`
    private_key=`echo "$account_private_key" | grep key | cut -d ' ' -f 3 | cut -c 3-`
    echo "0x$account" > /key-$i/account
    echo "$private_key" > /key-$i/private_key
    touch /key-$i/keys_done

    if [ $i -eq 0 ]; then
        sed -i "s/<yourInitialSigners>/$account/g" genesis.json
    fi
    i=$((i+1))
done

# initialize a private network according to https://github.com/ethereum/go-ethereum/wiki/Private-network
echo "Initializing private network"
geth init genesis.json

# run geth
echo "Running geth"
geth $@
