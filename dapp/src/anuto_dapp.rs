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
use super::tournament::reveal_commit::{RevealCommit, RevealCommitCtx, RevealCommitCtxParsed};
use super::tournament::{
    cartesi_base, MachineTemplate,
    MatchManager,
    NewSessionRequest, NewSessionResult,
    EMULATOR_SERVICE_NAME, EMULATOR_METHOD_NEW};

pub struct AnutoDApp();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
pub struct AnutoDAppCtxParsed(
    String32Field,  // name of the tournament
    Bytes32Field,  // setupHash
    U256Field,  // finalTime
    String32Field // currentState
);

#[derive(Serialize, Debug)]
pub struct AnutoDAppCtx {
    pub tournament_name: String,
    pub setup_hash: H256,
    pub final_time: U256,
    pub level: U256,
    pub current_state: String
}

impl From<AnutoDAppCtxParsed> for AnutoDAppCtx {
    fn from(parsed: AnutoDAppCtxParsed) -> AnutoDAppCtx {
        AnutoDAppCtx {
            tournament_name: parsed.0.value,
            setup_hash: parsed.1.value,
            final_time: parsed.2.value,
            level: parsed.3.value,
            current_state: parsed.4.value
        }
    }
}

impl DApp<()> for AnutoDApp {
    /// React to the DApp contract, WaitingCommitAndReveal/WaitingMatches/DAppFinished
    fn react(
        instance: &state::Instance,
        archive: &Archive,
        post_action: &Option<String>,
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

                let reveal_parsed: RevealCommitCtxParsed =
                    serde_json::from_str(&reveal_instance.json_data)
                        .chain_err(|| {
                            format!(
                                "Could not parse reveal instance json_data: {}",
                                &reveal_instance.json_data
                            )
                        })?;
                let reveal_ctx: RevealCommitCtx = reveal_parsed.into();

                if reveal_ctx.current_state == "CommitRevealDone" {
                    let request = TransactionRequest {
                        concern: instance.concern.clone(),
                        value: U256::from(0),
                        function: "claimMatches".into(),
                        data: vec![
                            Token::Uint(instance.index),
                        ],
                        strategy: transaction::Strategy::Simplest,
                    };

                    return Ok(Reaction::Transaction(request));

                }
                let machine_request = build_machine().chain_err(|| format!("could not build machine message"))?;
                let machine_template: MachineTemplate = MachineTemplate {
                    machine: machine_request,
                    drive_path: "anuto-log.ext2".to_string(),
                    final_time: ctx.final_time.as_u64()
                };

                // if reveal is still active, pass control
                return RevealCommit::react(reveal_instance, archive, post_action, &machine_template);
            },
            "WaitingMatches" => {
                // we inspect the match manager contract
                let match_manager_instance = instance.sub_instances.get(1).ok_or(
                    Error::from(ErrorKind::InvalidContractState(format!(
                        "There is no match manager instance {}",
                        ctx.current_state
                    ))),
                )?;

                let machine_request = build_machine().chain_err(|| format!("could not build machine message"))?;
                let machine_template: MachineTemplate = MachineTemplate {
                    machine: machine_request,
                    drive_path: "anuto-log.ext2".to_string(),
                    final_time: ctx.final_time.as_u64()
                };
                
                return MatchManager::react(match_manager_instance, archive, &None, &machine_template);
                // return control to match manager
            }
            _ => {
                return Ok(Reaction::Idle);
            }
        };
    }
    
    fn get_pretty_instance(
        instance: &state::Instance,
        archive: &Archive,
        _: &(),
    ) -> Result<state::Instance> {
        
        // get context (state) of the arbitration test instance
        let parsed: AnutoDAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse arbitration test instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: AnutoDAppCtx = parsed.into();
        let json_data = serde_json::to_string(&ctx).unwrap();

        // get context (state) of the sub instances

        let mut pretty_sub_instances : Vec<Box<state::Instance>> = vec![];

        pretty_sub_instances.push(
            Box::new(
                RevealCommit::get_pretty_instance(
                    instance.sub_instances.get(0).unwrap(),
                    archive,
                    &Default::default(),
                )
                .unwrap()
            )
        );

        if instance.sub_instances.len() > 1 {
            pretty_sub_instances.push(
                Box::new(
                    MatchManager::get_pretty_instance(
                        instance.sub_instances.get(1).unwrap(),
                        archive,
                        &Default::default(),
                    )
                    .unwrap()
                )
            );
        }

        let pretty_instance = state::Instance {
            name: "AnutoDApp".to_string(),
            concern: instance.concern.clone(),
            index: instance.index,
            json_data: json_data,
            sub_instances: pretty_sub_instances,
        };

        return Ok(pretty_instance)
    }
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// below are the codes to generate hard-coded new machine request 
// may need to revise in the future
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// TODO: revise all the values below for the anuto game
macro_rules! drive_label_0 {
    () => ( "rootfs" )
}
macro_rules! drive_label_1 {
    () => ( "anutofs" )
}
macro_rules! drive_label_2 {
    () => ( "log" )
}
macro_rules! drive_label_3 {
    () => ( "level" )
}
macro_rules! drive_label_4 {
    () => ( "output" )
}

macro_rules! mtdparts_string {
    () => ( concat!(
            "mtdparts=flash.0:-(", drive_label_0!(), ")",
            "flash.1:-(", drive_label_1!(), ")",
            "flash.2:-(", drive_label_2!(), ")",
            "flash.3:-(", drive_label_3!(), ")",
            "flash.4:-(", drive_label_4!(), ")");
    )
}

const EMULATOR_BASE_PATH: &'static str = "/root/host/";
const TEST_BASE_PATH: &'static str = "/root/host/test-files/";

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
    label: &'static str,
    start: u64,
    length: u64
}

const TEST_RAM: Ram = Ram {
    length: 512 << 20,
    backing: "kernel.bin"
};

const TEST_DRIVES: [Drive; 5] = [
    Drive {
        backing: concat!(drive_label_0!(), ".ext2"),
        shared: false,
        label: drive_label_0!(),
        start: 0x8000000000000000,
        length: 0x3c00000
    }, 
    Drive {
        backing: concat!(drive_label_1!(), ".ext2"),
        shared: false,
        label: drive_label_1!(),
        start: 0xa000000000000000,
        length: 0x400000
    },
    Drive {
        backing: concat!(drive_label_2!(), ".json.br.tar"),
        shared: false,
        label: drive_label_2!(),
        start: 0xc000000000000000,
        length: 0x3000
    },
    Drive {
        backing: concat!(drive_label_3!(), ".ext2"),
        shared: false,
        label: drive_label_3!(),
        start: 0xd000000000000000,
        length: 0x1000
    },
    Drive {
        backing: concat!(drive_label_4!(), ".ext2"),
        shared: false,
        label: drive_label_4!(),
        start: 0xe000000000000000,
        length: 0x1000
    }
];

const TEST_ROM: Rom = Rom {
    bootargs: concat!("console=hvc0 rootfstype=ext2 root=/dev/mtdblock0 rw ",
                    mtdparts_string!(),
                    " quiet -- /mnt/anuto/bin/verify"),
    backing: "rom.bin"
};

fn build_machine() -> Result<cartesi_base::MachineRequest> {
    let mut ram_msg = cartesi_base::RAM::new();
    ram_msg.set_length(TEST_RAM.length);
    ram_msg.set_backing(EMULATOR_BASE_PATH.to_string() + &TEST_RAM.backing.to_string());

    let mut drives_msg: Vec<cartesi_base::Drive> = Vec::new();

    for drive in TEST_DRIVES.iter() {
        let drive_path = EMULATOR_BASE_PATH.to_string() + &drive.backing.to_string();
        let mut drive_msg = cartesi_base::Drive::new();

        drive_msg.set_start(drive.start);
        drive_msg.set_length(drive.length);
        drive_msg.set_backing(drive_path);
        drive_msg.set_shared(drive.shared);

        drives_msg.push(drive_msg);
    }

    let mut rom_msg = cartesi_base::ROM::new();
    rom_msg.set_bootargs(TEST_ROM.bootargs.to_string());
    rom_msg.set_backing(EMULATOR_BASE_PATH.to_string() + &TEST_ROM.backing.to_string());

    let mut machine = cartesi_base::MachineRequest::new();
    machine.set_rom(rom_msg);
    machine.set_ram(ram_msg);
    machine.set_flash(protobuf::RepeatedField::from_vec(drives_msg));

    return Ok(machine);
}
