#!/usr/bin/env luapp5.3

-- Copyright 2019 Cartesi Pte. Ltd.
--
-- This file is part of the machine-emulator. The machine-emulator is free
-- software: you can redistribute it and/or modify it under the terms of the GNU
-- Lesser General Public License as published by the Free Software Foundation,
-- either version 3 of the License, or (at your option) any later version.
--
-- The machine-emulator is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
-- for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with the machine-emulator. If not, see http://www.gnu.org/licenses/.
--

local cartesi = require"cartesi"

local PAGE_LENGTH             = 1<<12

local ROOT_DEVICE_START       = (1<<63)+(0<<61)
local ROOT_DEVICE_LENGTH      = nil -- auto-detect for now
local ROOT_DEVICE_BACKING     = "rootfs.ext2"
local ANUTO_DEVICE_START      = (1<<63)+(1<<61)
local ANUTO_DEVICE_LENGTH     = nil -- auto-detect for now
local ANUTO_DEVICE_BACKING    = "anutofs.ext2"
local LOG_DEVICE_START        = (1<<63)+(2<<61)
local LOG_DEVICE_LOG2_SIZE    = nil -- auto-detect for now
local LOG_DEVICE_LENGTH       = nil -- auto-detect for now
local LOG_DEVICE_BACKING      = nil
local LEVEL_DEVICE_START      = (1<<63)+(2<<61)+(1<<60)
local LEVEL_DEVICE_LOG2_SIZE  = 12 -- 4KB
local LEVEL_DEVICE_LENGTH     = 1 << LEVEL_DEVICE_LOG2_SIZE
local LEVEL_DEVICE_BACKING    = nil -- "level.bin"
local OUTPUT_DEVICE_START     = (1<<63)+(3<<61)
local OUTPUT_DEVICE_LOG2_SIZE = 12 -- 4KB
local OUTPUT_DEVICE_LENGTH    = 1 << OUTPUT_DEVICE_LOG2_SIZE
local OUTPUT_DEVICE_BACKING   = nil -- "output.bin"
local RAM_LENGTH              = 512<<20 -- 512MB
local RAM_IMAGE               = "kernel.bin"
local ROM_IMAGE               = "rom.bin"

local print_proofs            = false
local auto_length             = false
local print_config            = false
local level                   = nil
local max_mcycle              = 1<<61   -- reduce significantly before release

-- Print help and exit
local function help()
    io.stderr:write([=[
Usage:
  anuto.lua [options]
where options are:
  --auto-length                set device length from backing

  --print-config               outputs bootargs and flash drive config

  --log-backing=<filename>     backing file for log

  --output-backing=<filename>  backing file for output
                               (default: prints result to stdout)

  --level-backing=<filename>   backing file for level
                               (default: writes directly to machine memory)

  --root-backing=<filename>    backing file for root filesystem
                               (default: "rootfs.ext2")

  --anuto-backing=<filename>   backing file for anuto filesystem
                               (default: "anutofs.ext2")

  --rom-image=<filename>       image file for ROM
                               (default: "rom.bin")

  --ram-image=<filename>       image file for RAM
                               (default: "kernel.bin")

  --print-proofs               print a variety of proofs
                               1) Proof of level still zeroed in memory before
                               it or the game log are written to their drives
                               2) Proof of the level after it is written, but
                               before the log is written
                               3) Proof of the log after the level is written,
                               bug before the log itself is written
                               4) Proof of the log after it and the level are
                               written
                               5) Proof of the score after the machine is run
                               on the log and level

  --level=<number>             level against which to score log

  --max-mcycle                 stop at a given mcycle
]=])
    os.exit()
end

-- List of supported options
-- Options are processed in order
-- For each option,
--   first entry is the pattern to match
--   second entry is a callback
--     if callback returns true, the option is accepted.
--     if callback returns false, the option is rejected.
local options = {
    { "^%-%-help$", function(all)
        if all then
            help()
            return true
        else
            return false
        end
    end },
    { "^%-%-auto%-length$", function(all)
        if not all then return false end
        auto_length = true
        return true
    end },
    { "^%-%-print%-config$", function(all)
        if not all then return false end
        print_config = true
        return true
    end },
    { "^%-%-print%-proofs$", function(all)
        if not all then return false end
        print_proofs = true
        return true
    end },
    { "^%-%-log%-backing%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        LOG_DEVICE_BACKING = o
        return true
    end },
    { "^%-%-output%-backing%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        OUTPUT_DEVICE_BACKING = o
        return true
    end },
    { "^%-%-level%-backing%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        LEVEL_DEVICE_BACKING = o
        return true
    end },
    { "^%-%-anuto%-backing%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        ANUTO_DEVICE_BACKING = o
        return true
    end },
    { "^%-%-root%-backing%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        ROOT_DEVICE_BACKING = o
        return true
    end },
    { "^%-%-ram%-image%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        RAM_IMAGE = o
        return true
    end },
    { "^%-%-rom%-image%=(.*)$", function(o)
        if not o or #o < 1 then return false end
        ROM_IMAGE = o
        return true
    end },
    { "^(%-%-level%=(%d+)(.*))$", function(all, n, e)
        if not n then return false end
        assert(e == "", "invalid option " .. all)
        n = assert(tonumber(n), "invalid option " .. all)
        assert(n >= 0, "invalid option " .. all)
        level = math.ceil(n)
        return true
    end },
    { "^(%-%-max%-mcycle%=(%d+)(.*))$", function(all, n, e)
        if not n then return false end
        assert(e == "", "invalid option " .. all)
        n = assert(tonumber(n), "invalid option " .. all)
        assert(n >= 0, "invalid option " .. all)
        max_mcycle = math.ceil(n)
        return true
    end },
    { ".*", function(all)
        error("unrecognized option " .. all)
    end }
}

-- Process command line options
for i, a in ipairs(arg) do
    for j, option in ipairs(options) do
        if option[2](a:match(option[1])) then
            break
        end
    end
end

assert(tonumber(level), "need --level argument")

-- create or rewrite level drive
if LEVEL_DEVICE_BACKING then
    local f = assert(io.open(LEVEL_DEVICE_BACKING, "wb"),
        "unable to open level device backing for writing")
    assert(f:write( string.pack(">I8", level) ..
        string.rep("\0", LEVEL_DEVICE_LENGTH-8)),
        "unable to initialize level device backing")
    f:close()
end

-- create or rewrite output drive
if OUTPUT_DEVICE_BACKING then
    local f = assert(io.open(OUTPUT_DEVICE_BACKING, "wb"),
        "unable to open output device backing for writing")
    assert(f:write(string.rep("\0", OUTPUT_DEVICE_LENGTH)),
        "unable to zero out output device backing")
    f:close()
end

local function intlog2(value)
    local i = 1
    local j = 1
    while i < value do
        i = i*2
        j = j+1
    end
    return j
end

local function get_file_length(filename)
    local file = io.open(filename, "rb")
    if not file then return nil end
    local size = file:seek("end")    -- get file size
    file:close()
    return size
end

local flash = {
    {
        label = "root",
        start = ROOT_DEVICE_START,
        length = ROOT_DEVICE_LENGTH,
        backing = ROOT_DEVICE_BACKING,
    },
    {
        label = "anuto",
        start = ANUTO_DEVICE_START,
        length = ANUTO_DEVICE_LENGTH,
        backing = ANUTO_DEVICE_BACKING,
    },
    {
        label = "log",
        start = LOG_DEVICE_START,
        length = LOG_DEVICE_LENGTH,
        backing = LOG_DEVICE_BACKING,
    },
    {
        label = "level",
        start = LEVEL_DEVICE_START,
        length = LEVEL_DEVICE_LENGTH,
        backing = LEVEL_DEVICE_BACKING,
    },
    {
        label = "output",
        start = OUTPUT_DEVICE_START,
        length = OUTPUT_DEVICE_LENGTH,
        backing = OUTPUT_DEVICE_BACKING,
        shared = (OUTPUT_DEVICE_BACKING ~= nil),
    }
}

-- figure out all device sizes if command line asks for it
if auto_length then
    for i,f in ipairs(flash) do
        if not f.length and f.backing then
            f.length = get_file_length(f.backing)
        end
        if not f.length then
            error(string.format("unable to get length for %s from backing '%s'",
                f.label, f.backing))
        end
    end
end

for i,f in ipairs(flash) do
    if not f.length then
        error(string.format("need length for %s device", f.label))
    end
    if f.length % PAGE_LENGTH ~= 0 then
        error(string.format("length for %s device must be multiple of %d",
            f.label, PAGE_LENGTH))
    end
end

local ram = {
    length = RAM_LENGTH,
    backing = RAM_IMAGE,
}

-- start with basic settings
local bootargs = "console=hvc0 rootfstype=ext2 root=/dev/mtdblock0 rw"

-- add labels for each flash device
local mtdparts = { }
for i,f in ipairs(flash) do
    mtdparts[#mtdparts+1] =
        string.format("flash.%d:-(%s)", i-1, f.label)
end
bootargs = bootargs .. " mtdparts=" .. table.concat(mtdparts, ";")

-- add command line to run verifier
bootargs = bootargs .. " quiet -- /mnt/anuto/bin/verify"

local rom = {
    bootargs = bootargs,
    backing = ROM_IMAGE
}

local config = {
    machine = cartesi.get_name(),
    rom = rom,
    ram = ram,
    flash = flash,
    -- interactive = true -- comment out before release
}

local function assert_proof(proof)
    assert(proof, "proof generation failed")
    local hash = proof.target_hash
    for log2_size = proof.log2_size, 63 do
        local bit = (proof.address & (1 << log2_size)) ~= 0
        local first, second
        if bit then
            first, second = proof.sibling_hashes[63-log2_size+1], hash
        else
            first, second = hash, proof.sibling_hashes[63-log2_size+1]
        end
        hash = cartesi.keccak(first, second)
    end
    assert(hash == proof.root_hash, "proof verification failed")
    return proof
end

local function clone(t)
    if type(t) == "table" then
        local u = {}
        for i,v in pairs(t) do
            assert(type(i) ~= "table", "table indices not supported")
            u[i] = clone(v)
        end
        return u
    else return t end
end

if print_config then
    io.write("bootargs:\n  '", bootargs, "'\n")
    io.write("flash devices:\n")
    for i,f in ipairs(flash) do
        io.write("  ", f.label, ":\n")
        io.write(string.format(    "    range:   %016x: %016x\n", f.start, f.length))
        if f.backing then
            io.write(string.format("    backing: (%s)\n", f.backing))
        end
    end
end

local function hexaddress(address)
    return string.format("0x%016x", address)
end

local function hexbytes(hash)
    return (string.gsub(hash, ".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

local function print_json_proof_sibling_hashes(sibling_hashes, log2_size,
    out, indent)
    out:write('[\n')
    for i, h in ipairs(sibling_hashes) do
        out:write(indent,'"', hexbytes(h), '"')
        if sibling_hashes[i+1] then out:write(',\n') end
    end
    out:write(' ]')
end

local function print_json_proof(proof, out, indent)
    out:write('{\n')
    out:write(indent, '"address": ', hexaddress(proof.address), ',\n')
    out:write(indent, '"log2_size": ', proof.log2_size, ',\n')
    out:write(indent, '"target_hash": "', hexbytes(proof.target_hash), '",\n')
    out:write(indent, '"sibling_hashes": ')
    print_json_proof_sibling_hashes(proof.sibling_hashes, proof.log2_size, out,
        indent .. "  ")
    out:write(",\n", indent, '"root_hash": "', hexbytes(proof.root_hash), '" }')
end

local machine = cartesi.machine(config)

if not LEVEL_DEVICE_BACKING then
    -- write level directly to memory in big-endian format
    machine:write_memory(LEVEL_DEVICE_START, string.pack(">I8", level))
end

if print_proofs then
    -- create a copy of the configuration so we can modify it
    local prove_level_config = clone(config)
    -- make sure level and log devices have no backing so they are pristine
    -- (i.e., filled with zeros) when we instantiate the machine
    for i, f in ipairs(prove_level_config.flash) do
        if f.start == LEVEL_DEVICE_START or f.start == LOG_DEVICE_START then
            f.backing = nil
        end
    end
    -- instantiate a temporary machine and get proof for the
    -- word containing the level (which should be zero at this point)
    local prove_level_machine = assert(cartesi.machine(prove_level_config))
    io.stderr:write("computing state merkle tree\n")
    assert(prove_level_machine:update_merkle_tree())
    local proof = assert_proof(prove_level_machine:get_proof(
        LEVEL_DEVICE_START, 3))
    local be_level = assert(prove_level_machine:read_memory(
        LEVEL_DEVICE_START, 8))
    -- dump as json
    io.stdout:write("level_before_write = {\n")
    io.stdout:write("  \"level\": \"", hexbytes(be_level), "\",\n")
    io.stdout:write("  \"proof\": ")
    print_json_proof(proof, io.stdout, "    ")
    io.stdout:write(" }\n")
    prove_level_machine:destroy()

    -- restore level backing to config (if any)
    -- get log device size from config (rounded up to next power of two)
    local log_device_log2_size
    for i, f in ipairs(prove_level_config.flash) do
        if f.start == LEVEL_DEVICE_START then
            f.backing = LEVEL_DEVICE_BACKING
        end
        if f.start == LOG_DEVICE_START then
            log_device_log2_size = intlog2(f.length)
        end
    end
    -- instantiate a new temporary machine to obtain proofs
    prove_level_machine = assert(cartesi.machine(prove_level_config))
    if not LEVEL_DEVICE_BACKING then
        -- write level directly to memory in big-endian format
        prove_level_machine:write_memory(LEVEL_DEVICE_START,
            string.pack(">I8", level))
    end
    -- get proof for word containing level, which should now be whatever was
    -- passed in the command line
    io.stderr:write("computing state merkle tree\n")
    assert(prove_level_machine:update_merkle_tree())
    proof = assert_proof(prove_level_machine:get_proof(LEVEL_DEVICE_START, 3))
    be_level = assert(prove_level_machine:read_memory(LEVEL_DEVICE_START, 8))
    io.stdout:write("level_after_write = {\n")
    io.stdout:write("  \"level\": \"", hexbytes(be_level), "\",\n")
    io.stdout:write("  \"proof\": ")
    print_json_proof(proof, io.stdout, "    ")
    io.stdout:write(" }\n")
    -- get proof for empty log drive
    proof = assert_proof(prove_level_machine:get_proof(LOG_DEVICE_START,
        log_device_log2_size))
    io.stdout:write("log_before_write = {\n")
    io.stdout:write("  \"proof\": ")
    print_json_proof(proof, io.stdout, "    ")
    io.stdout:write(" }\n")
    prove_level_machine:destroy()
    -- get proof for log drive in complete machine
    io.stderr:write("computing state merkle tree\n")
    assert(machine:update_merkle_tree())
    proof = assert_proof(machine:get_proof(LOG_DEVICE_START,
        log_device_log2_size))
    io.stdout:write("log_after_write = {\n")
    io.stdout:write("  \"proof\": ")
    print_json_proof(proof, io.stdout, "    ")
    io.stdout:write(" }\n")
end

-- run machine until it halts or reaches max_mcycle
machine:run(max_mcycle)
local mcycle = machine:read_mcycle()

-- if machine is halted, read score back and print
-- other print score zero
if machine:read_iflags_H() then
    -- read output device back
    local output = machine:read_memory(OUTPUT_DEVICE_START, OUTPUT_DEVICE_LENGTH)
    -- unpack big-endian score and potential error message
    local score, msg = string.unpack(">I8z", output)
    print(score, msg, mcycle)
else
    print(0, "machine has not halted", mcycle)
end

-- print a proof of the
if print_proofs then
    io.stderr:write("computing state merkle tree\n")
    assert(machine:update_merkle_tree())
    io.stdout:write("score_at_completion = {\n")
    local be_score = assert(machine:read_memory(OUTPUT_DEVICE_START, 8))
    io.stdout:write("  \"score\": \"", hexbytes(be_score), "\",\n")
    local proof = assert_proof(machine:get_proof(OUTPUT_DEVICE_START, 3))
    io.stdout:write("  \"proof\": ")
    print_json_proof(proof, io.stdout, "    ")
    io.stdout:write(" }\n")
end
