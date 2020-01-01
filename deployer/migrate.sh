#!/bin/sh

echo "Unlocking account if geth is used"
truffle exec /opt/cartesi/deployer/unlockAccount.js --network ${ETHEREUM_NETWORK}

find *

echo "Deploying @cartesi/util"
cd node_modules/@cartesi/util && truffle migrate --network ${ETHEREUM_NETWORK} && cd ../../..

echo "Deploying @cartesi/arbitration"
cd node_modules/@cartesi/arbitration && truffle migrate --network ${ETHEREUM_NETWORK} && cd ../../..

echo "Deploying @cartesi/machine-solidity-step"
cd node_modules/@cartesi/machine-solidity-step && truffle migrate --network ${ETHEREUM_NETWORK} && cd ../../..

echo "Deploying @cartesi/logger"
# TODO: create ganache network configuration for logger
cd node_modules/@cartesi/logger && truffle migrate --network ${ETHEREUM_NETWORK} && cd ../../..

echo "Deploying @cartesi/tournament"
cd node_modules/@cartesi/tournament && truffle migrate --network ${ETHEREUM_NETWORK} && cd ../../..

echo "Deploying creepts"
truffle migrate --network ${ETHEREUM_NETWORK}
