#!/bin/sh

if [ "$#" -ne 2 ] || ! [ -f "$2" ]; then
  echo "Usage: $0 <dispatcher enpoint> <log.br.cpio path>" >&2
  exit 1
fi

rm data.json

log_hash=`docker run -v $(pwd):/program cartesi/machine-emulator:0.1.0-rc5 cartesi-machine-hash --page-log2-size=10 --tree-log2-size=20 --input=/program/$2`

sed "s/LogHash/0x$log_hash/g" data-template.json > data.json
echo "Committing log hash: $log_hash to dispatcher: $1..."
curl -X POST -H "Content-Type: application/json" -d "@data.json" $1
echo "\nDone!"
