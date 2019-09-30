# Copyright 2019 Cartesi Pte. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

UNAME:=$(shell uname)

# Containers tags
TOOLCHAIN_TAG ?= latest

FSDIR := fs
DEPDIR := third-party
SRCDIR := $(abspath src)
DOWNLOADDIR := $(DEPDIR)/downloads

CONTAINER_BASE := /opt/cartesi/anuto-dapp
CONTAINER_MAKE := /usr/bin/make

RVCC  = riscv64-unknown-linux-gnu-gcc
RVCXX = riscv64-unknown-linux-gnu-g++
RVCOPY = riscv64-unknown-linux-gnu-objcopy
RVDUMP = riscv64-unknown-linux-gnu-objdump
RISCV_CFLAGS :=-march=rv64ima -mabi=lp64

DJSDIR = $(DEPDIR)/duktape-2.4.0
DJS = $(DJSDIR)/djs
VIMDIR = $(DEPDIR)/vim-8.1.2069
XXDDIR = $(VIMDIR)/src/xxd
XXD = $(XXDDIR)/xxd
FSDIR = fs

DEPDIRS := $(DJSDIR) $(VIMDIR)

fs: anutofs.ext2

anutofs.ext2: $(FSDIR)/bin/djs $(FSDIR)/bin/xxd $(FSDIR)/bin/* $(FSDIR)/levels/*
	$(MAKE) toolchain-exec CONTAINER_COMMAND="$(CONTAINER_MAKE) $@.toolchain"

$(FSDIR)/bin/djs: $(DJS)
	cp -f $< $@

$(DJS): $(DEPDIR)/duktape-2.4.0
	$(MAKE) toolchain-exec CONTAINER_COMMAND="$(CONTAINER_MAKE) $@.toolchain"

$(DJS).toolchain:
	$(MAKE) -C $(DJSDIR) -f Makefile.djs CC=$(RVCC)

$(FSDIR)/bin/xxd: $(XXD)
	cp -f $< $@

$(XXD): $(DEPDIR)/vim-8.1.2069
	$(MAKE) toolchain-exec CONTAINER_COMMAND="$(CONTAINER_MAKE) $@.toolchain"

$(XXD).toolchain:
	$(MAKE) -C $(XXDDIR) CC=$(RVCC)

anutofs.ext2.toolchain:
	genext2fs -f -i 512 -b 4096 -d fs $(basename $@)
	truncate -s %4096 $(basename $@)

$(DEPDIR)/vim-8.1.2069: | downloads
	tar -xzvf $(DOWNLOADDIR)/v8.1.2069.tar.gz -C $(DEPDIR) vim-8.1.2069/src/xxd

$(DEPDIR)/duktape-2.4.0: | downloads
	tar -xJvf $(DOWNLOADDIR)/duktape-2.4.0.tar.xz -C $(DEPDIR)
	cd $@ && patch -p1 < ../duktape-2.4.0.patch

downloads:
	mkdir -p $(DOWNLOADDIR)
	wget -nc -i $(DEPDIR)/dependencies -P $(DOWNLOADDIR)
	cd $(DEPDIR) && shasum -c shasumfile

toolchain-exec:
	@docker run --hostname $@ --rm \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		cartesi/image-toolchain:$(TOOLCHAIN_TAG) $(CONTAINER_COMMAND)

toolchain-env:
	@docker run --hostname toolchain-env -it --rm \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		cartesi/image-toolchain:$(TOOLCHAIN_TAG)

clean:
	\rm -rf anutofs.ext2 $(FSDIR)/bin/djs $(DJS) $(FSDIR)/bin/xxd $(XXD) $(DOWNLOADDIR) $(DEPDIRS)

.PHONY: toolchain-exec djs build-djs xxd build-xxd clean downloads $(XXD).toolchain $(DJS).toolchain anutofs.ext2.toolchain
