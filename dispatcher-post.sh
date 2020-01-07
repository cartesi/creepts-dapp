#!/bin/sh

rm data-0.json data-1.json

log_hash_0=`docker run -v $(pwd):/program cartesi/machine-emulator:0.1.0-rc5 cartesi-machine-hash --page-log2-size=10 --tree-log2-size=20 --input=/program/dapp_data_0/0.json.br.cpio`
log_hash_1=`docker run -v $(pwd):/program cartesi/machine-emulator:0.1.0-rc5 cartesi-machine-hash --page-log2-size=10 --tree-log2-size=20 --input=/program/dapp_data_1/1.json.br.cpio`

dispatcher_ip_0=`docker inspect anutodapp_dispatcher_0_1 | grep IPAddress | tail -n 1 | cut -d'"' -f 4`
dispatcher_ip_1=`docker inspect anutodapp_dispatcher_1_1 | grep IPAddress | tail -n 1 | cut -d'"' -f 4`

sed "s/LogHash/0x$log_hash_0/g" data-template.json > data-0.json
echo "Committing log hash 0: $log_hash_0 to dispatcher 0: $dispatcher_ip_0..."
curl -X POST -H "Content-Type: application/json" -d "@data-0.json" $dispatcher_ip_0:3001
echo "\nDone!"

sed "s/LogHash/0x$log_hash_1/g" data-template.json > data-1.json
echo "Committing log hash 1: $log_hash_1 to dispatcher 1: $dispatcher_ip_1..."
curl -X POST -H "Content-Type: application/json" -d "@data-1.json" $dispatcher_ip_1:3001
echo "\nDone"
