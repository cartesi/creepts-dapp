#!/bin/sh

# exit when any command fails
set -e

if [ -z "${MNEMONIC}" ]; then
    echo "No MNEMONIC, waiting for key file at /opt/cartesi/etc/keys/"
    dockerize -wait file:///opt/cartesi/etc/keys/keys_done -timeout ${ETHEREUM_TIMEOUT}

    export CARTESI_CONCERN_KEY=$(cat /opt/cartesi/etc/keys/private_key)
    export ACCOUNT_ADDRESS=$(cat /opt/cartesi/etc/keys/account)
else
    echo "Initializing key and account from MNEMONIC"
    export CARTESI_CONCERN_KEY=$(wagyu ethereum import-hd --mnemonic "${MNEMONIC}" --derivation "m/44'/60'/0'/0/${ACCOUNT_INDEX}" --json | jq -r '.[0].private_key')
    export ACCOUNT_ADDRESS=$(wagyu ethereum import-hd --mnemonic "${MNEMONIC}" --derivation "m/44'/60'/0'/0/${ACCOUNT_INDEX}" --json | jq -r '.[0].address')
fi

# if a network id is set we assume deployment is already done, no need to wait for it
if [ -z "${NETWORK_ID}" ]; then
    echo "Waiting for blockchain deployment..."
    dockerize -wait file:///opt/cartesi/share/blockchain/deploy_done -timeout ${ETHEREUM_TIMEOUT}
fi

echo "Waiting for services..."
dockerize \
    -wait tcp://${ETHEREUM_HOST}:${ETHEREUM_PORT} \
    -wait tcp://machine-manager:50051 \
    -wait tcp://logger:50051 \
    -timeout ${ETHEREUM_TIMEOUT}

echo "Creating configuration file at /opt/cartesi/etc/creepts/config.yaml with account ${ACCOUNT_ADDRESS}"
envsubst < /opt/cartesi/etc/creepts/config-template.yaml > /opt/cartesi/etc/creepts/config.yaml
cat /opt/cartesi/etc/creepts/config.yaml

echo "Starting dispatcher"
/opt/cartesi/bin/creepts --config_path /opt/cartesi/etc/creepts/config.yaml --working_path /opt/cartesi/srv/creepts
