#!/bin/sh

export CARTESI_CONCERN_KEY=`cat /opt/cartesi/etc/keys/private_key`
export ACCOUNT_ADDRESS=`cat /opt/cartesi/etc/keys/account`
echo "Creating configuration file at /opt/cartesi/etc/creepts/config.yaml with account ${ACCOUNT_ADDRESS}"
envsubst < /opt/cartesi/etc/creepts/config-template.yaml > /opt/cartesi/etc/creepts/config.yaml
cat /opt/cartesi/etc/creepts/config.yaml

/opt/cartesi/bin/creepts --config_path /opt/cartesi/etc/creepts/config.yaml --working_path /opt/cartesi/srv/creepts
