#!/bin/sh

set -e

/root/download_asset.sh cartesi-corp anuto v0.1.0-alpha.1 creeptsfs.ext2
wget --no-verbose https://github.com/cartesi/image-kernel/releases/download/v0.1.0/kernel.bin
wget --no-verbose https://github.com/cartesi/machine-emulator-rom/releases/download/v0.1.0/rom.bin
wget --no-verbose https://github.com/cartesi/image-rootfs/releases/download/v0.1.0/rootfs.ext2
touch files_done
