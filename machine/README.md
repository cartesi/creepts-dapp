# Anuto's Cartesi Machine

This is the Cartesi Machine that produces the score given a log for the Anuto
game.

## Getting Started

### Requirements

This prototype uses the cartesi.so library to run the emulator. It also needs
the rootfs.ext2, rom.bin, and kernel.bin files. The building process uses
the image-toolchain Docker image. These are all products of the machine-emulator-sdk repository.

Building:

```bash
$ make
```
This should produce anutofs.ext2.

Cleaning:

```bash
$ make clean
```

## Running Tests

Make sure your environment variables are set so the machine-emulator and its
dependencies can be found. In your development environment, go to the
machine-emulator directory and type

```bash
$ make env
```

to get the variables you will need.

Then, copy rootfs.ext2, rom.bin, and kernel.bin to the working directory where
you have anutofs.ext2 and anuto.lua.

Now you need to obtain a Brotli compressed, then TAR'd log matching one of the
logs in test-logs. For example:

```bash
$ packlog test-logs/22.json 22.json.br.tar
```

You are finally ready to run the verifier on this log.

```bash
$ ./anuto.lua --log-backing=22.json.br.tar --level=22 --auto-length
```

This should run the verifier and print a variety of diagnostics information on
the screen:

```
bootargs
        console=hvc0 rootfstype=ext2 root=/dev/mtdblock0 rw
mtdparts=flash.0:-(root);flash.1:-(anuto);flash.2:-(log);flash.3:-(level);flash.4:-(output)
quiet -- /mnt/anuto/bin/verify
root
        8000000000000000
        0000000003c00000
        rootfs.ext2
anuto
        a000000000000000
        0000000000400000
        anutofs.ext2
log
        c000000000000000
        0000000000001000
        22.json.br.tar
level
        d000000000000000
        0000000000001000
        nil
output
        e000000000000000
        0000000000001000
        nil
bbl loader
[    0.000000] OF: fdt: Ignoring memory range 0x80000000 - 0x80200000
[    0.000000] Linux version 4.20.8 (root@cd89ca471931) (gcc version 8.3.0
(crosstool-NG 1.24.0)) #1 SMP Mon Sep 2 20:33:15 UTC 2019
[    0.000000] printk: bootconsole [early0] enabled
[    0.040000] EXT2-fs (mtdblock2): error: can't find an ext2 filesystem on dev
mtdblock2.
mount: /mnt/log: wrong fs type, bad option, bad superblock on /dev/mtdblock2,
missing codepage or helper program, or other error.
[    0.040000] EXT2-fs (mtdblock3): error: can't find an ext2 filesystem on dev
mtdblock3.
mount: /mnt/level: wrong fs type, bad option, bad superblock on /dev/mtdblock3,
missing codepage or helper program, or other error.
[    0.050000] EXT2-fs (mtdblock4): error: can't find an ext2 filesystem on dev
mtdblock4.
mount: /mnt/output: wrong fs type, bad option, bad superblock on /dev/mtdblock4,
missing codepage or helper program, or other error.
Getting log
8+0 records in
8+0 records out
Getting level
512+0 records in
8+0 records out
Running verification
Writing results
0+1 records in
0+1 records out
umount: /dev/mtdblock2: not mounted.
umount: /dev/mtdblock3: not mounted.
umount: /dev/mtdblock4: not mounted.
[    1.170000] reboot: Power down
Power off
200             1209604601
```

Don't worry about the error messages related to the mount/umount commands. We will get rid of them in due time.

In the last line, you can see the score, followed by an empty error message, and
then the value of mcycle.

Run

```bash
$ ./anuto.lua --help
```

for other options.

Read the Lua source for details on the layout of the machine.

## Authors

* *Diego Nehab*

## License

TBD
