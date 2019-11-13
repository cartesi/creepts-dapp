// Anuto DApp is the combination of the on-chain protocol and off-chain
// protocol that work together to distinguish the winner of a tower defense
// game tournament.

// Copyright (C) 2019 Cartesi Pte. Ltd.

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

extern crate protobuf;

use super::build_machine_id;
use super::dispatcher::{AddressField, Bytes32Field, String32Field, U256Field};
use super::dispatcher::{Archive, DApp, Reaction};
use super::error::Result;
use super::error::*;
use super::ethabi::Token;
use super::transaction;
use super::transaction::TransactionRequest;
use super::ethereum_types::{Address, H256, U256};
use super::compute::{
    cartesi_base,
    EMULATOR_SERVICE_NAME, EMULATOR_METHOD_NEW,
    NewSessionRequest, NewSessionResult};
use super::compute::{Compute, ComputeCtx, ComputeCtxParsed};
use std::fs;

pub struct AnutoDApp();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
struct AnutoDAppCtxParsed(
    String32Field,  // name of the tournament
    Bytes32Field,  // initialHash
    String32Field // currentState
);

#[derive(Debug)]
struct AnutoDAppCtx {
    tournament_name: String,
    initial_hash: H256,
    current_state: String
}

impl From<AnutoDAppCtxParsed> for AnutoDAppCtx {
    fn from(parsed: AnutoDAppCtxParsed) -> AnutoDAppCtx {
        AnutoDAppCtx {
            tournament_name: parsed.0.value,
            initial_hash: parsed.1.value,
            current_state: parsed.2.value
        }
    }
}

impl DApp<()> for AnutoDApp {
    /// React to the DApp contract, WaitingCommitAndReveal/WaitingMatches/DAppFinished
    fn react(
        instance: &state::Instance,
        archive: &Archive,
        _: &(),
    ) -> Result<Reaction> {
        // get context (state) of the DApp instance
        let parsed: AnutoDAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse dapp instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: AnutoDAppCtx = parsed.into();
        trace!("Context for dapp (index {}) {:?}", instance.index, ctx);

        match ctx.current_state.as_ref() {
            "DAppFinished" => {
                return Ok(Reaction::Idle);
            },
            "WaitingCommitAndReveal" => {
                // we inspect the reveal contract
                let reveal_instance = instance.sub_instances.get(0).ok_or(
                    Error::from(ErrorKind::InvalidContractState(format!(
                        "There is no reveal instance {}",
                        ctx.current_state
                    ))),
                )?;
                // return control to reveal
                return Reveal::react(reveal_instance, archive, &());
            },
            "WaitingMatches" => {
                // we inspect the match manager contract
                let match_manager_instance = instance.sub_instances.get(1).ok_or(
                    Error::from(ErrorKind::InvalidContractState(format!(
                        "There is no match manager instance {}",
                        ctx.current_state
                    ))),
                )?;
                match MatchManager::react(match_manager_instance, archive, &()) {
                    Ok(v) => {
                        return v;
                    },
                    Err(e) => {
                        match e.kind() {
                            ErrorKind::ArchiveMissError(service, key, method, request) => {
                                if service == EMULATOR_SERVICE_NAME &&
                                method == EMULATOR_METHOD_NEW {
                                    processed_request: NewSessionRequest = request.into();
                                    processed_request.machine = build_machine();
                                    return Error::from(ErrorKind::ArchiveMissError(service, key, method, processed_request.into()))
                                }
                                return e;
                            },
                            _ => {
                                return e;
                            }
                        }
                    }
                }
                // return control to match manager
            }
            _ => {}
        };

        // machine id
        let id = build_machine_id(
            instance.index,
            &instance.concern.contract_address,
        );
        let machine_request = build_machine();
        let request = NewSessionRequest {
            session_id: id.clone(),
            machine: machine_request
        };

        let duplicate_session_msg = format!("Trying to register a session with a session_id that already exists: {}", id);
        let _processed_response: NewSessionResult = archive.get_response(
            EMULATOR_SERVICE_NAME.to_string(),
            id.clone(),
            EMULATOR_METHOD_NEW.to_string(),
            request.into())?
            .map_err(move |e| {
                if e == duplicate_session_msg {
                    Error::from(ErrorKind::ArchiveNeedsDummy(
                        EMULATOR_SERVICE_NAME.to_string(),
                        id,
                        EMULATOR_METHOD_NEW.to_string()))
                } else {
                    Error::from(ErrorKind::ArchiveInvalidError(
                        EMULATOR_SERVICE_NAME.to_string(),
                        id,
                        EMULATOR_METHOD_NEW.to_string()))
                }
            })?
            .into();
        
        // we inspect the compute contract
        let compute_instance = instance.sub_instances.get(0).ok_or(
            Error::from(ErrorKind::InvalidContractState(format!(
                "There is no compute instance {}",
                ctx.current_state
            ))),
        )?;
        let compute_parsed: ComputeCtxParsed =
            serde_json::from_str(&compute_instance.json_data)
                .chain_err(|| {
                    format!(
                        "Could not parse compute instance json_data: {}",
                        &compute_instance.json_data
                    )
                })?;
        let compute_ctx: ComputeCtx = compute_parsed.into();

        match compute_ctx.current_state.as_ref() {
            "ClaimerMissedDeadline" |
            "ChallengerWon" |
            "ClaimerWon" |
            "ConsensusResult" => {
                // claim Finished in arbitration test contract
                let request = TransactionRequest {
                    concern: instance.concern.clone(),
                    value: U256::from(0),
                    function: "claimFinished".into(),
                    data: vec![Token::Uint(instance.index)],
                    strategy: transaction::Strategy::Simplest,
                };
                return Ok(Reaction::Transaction(request));
            }
            _ => {
                // compute is still active,
                // pass control to the appropriate dapp
                return Compute::react(compute_instance, archive, &());
            }
        }
    }
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// below are the codes to generate hard-coded new machine request 
// may need to revise in the future
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

macro_rules! drive_label_0 {
    () => ( "rootfs" )
}
macro_rules! drive_label_1 {
    () => ( "input" )
}
macro_rules! drive_label_2 {
    () => ( "job" )
}
macro_rules! drive_label_3 {
    () => ( "output" )
}

macro_rules! mtdparts_string {
    () => ( concat!(
            "mtdparts=flash.0:-(", drive_label_0!(), ")",
            "flash.1:-(", drive_label_1!(), ")",
            "flash.2:-(", drive_label_2!(), ")",
            "flash.3:-(", drive_label_3!(), ")");
    )
}

const ONEMB: u64 = 1024*1024;
const EMULATOR_BASE_PATH: &'static str = "/root/host/";
const TEST_BASE_PATH: &'static str = "/root/host/test-files/";
const OUTPUT_DRIVE_NAME: &'static str = "out_pristine.ext2";

struct Ram {
    length: u64,
    backing: &'static str
}

struct Rom {
    bootargs: &'static str,
    backing: &'static str
}

struct Drive {
    backing: &'static str,
    shared: bool,
    label: &'static str
}

const TEST_RAM: Ram = Ram {
    length: 64 << 20,
    backing: "kernel.bin"
};

const TEST_DRIVES: [Drive; 4] = [
    Drive {
        backing: concat!(drive_label_0!(), ".ext2"),
        shared: false,
        label: drive_label_0!()
    }, 
    Drive {
        backing: concat!(drive_label_1!(), ".ext2"),
        shared: false,
        label: drive_label_1!()
    }, 
    Drive {
        backing: concat!(drive_label_2!(), ".ext2"),
        shared: false,
        label: drive_label_2!()
    }, 
    Drive {
        backing: OUTPUT_DRIVE_NAME,
        shared: false,
        label: drive_label_3!()
    }
];

const TEST_ROM: Rom = Rom {
    bootargs: concat!("console=hvc0 rootfstype=ext2 root=/dev/mtdblock0 rw ",
                    mtdparts_string!(),
                    " -- /bin/sh -c 'echo test && touch /mnt/output/test && cat /mnt/job/demo.sh && /mnt/job/demo.sh && echo test2' && cat /mnt/output/out"),
    backing: "rom-linux.bin"
};

fn build_machine() -> cartesi_base::MachineRequest {
    let mut ram_msg = cartesi_base::RAM::new();
    ram_msg.set_length(TEST_RAM.length);
    ram_msg.set_backing(EMULATOR_BASE_PATH.to_string() + &TEST_RAM.backing.to_string());

    let mut drive_start: u64 = 1 << 63;
    let mut drives_msg: Vec<cartesi_base::Drive> = Vec::new();

    for drive in TEST_DRIVES.iter() {
        let drive_path = EMULATOR_BASE_PATH.to_string() + &drive.backing.to_string();
        // TODO: error handling for files metadata
        let metadata = fs::metadata(TEST_BASE_PATH.to_string() + &drive.backing.to_string());
        let drive_size = metadata.unwrap().len();
        let mut drive_msg = cartesi_base::Drive::new();

        drive_msg.set_start(drive_start);
        drive_msg.set_length(drive_size);
        drive_msg.set_backing(drive_path);
        drive_msg.set_shared(drive.shared);

        drives_msg.push(drive_msg);

        if drive_size < ONEMB {
            drive_start += ONEMB;
        } else {
            drive_start +=  drive_size.next_power_of_two();
        }
    }

    let mut rom_msg = cartesi_base::ROM::new();
    rom_msg.set_bootargs(TEST_ROM.bootargs.to_string());
    rom_msg.set_backing(EMULATOR_BASE_PATH.to_string() + &TEST_ROM.backing.to_string());

    let mut machine = cartesi_base::MachineRequest::new();
    machine.set_rom(rom_msg);
    machine.set_ram(ram_msg);
    machine.set_flash(protobuf::RepeatedField::from_vec(drives_msg));

    return machine;
}
