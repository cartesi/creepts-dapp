#!/bin/sh

echo "Unlocking account if geth is used"
truffle exec unlockAccount.js --network ${ETHEREUM_NETWORK}

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

echo "Collecting json build files into ./build"
mkdir -p ./build/contracts

# copy deployment files needed by dispatcher (config-template.yaml)
cat files | xargs -I % cp % ./build/contracts/

find ./build
