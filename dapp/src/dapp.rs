// Creepts DApp is the combination of the on-chain protocol and off-chain
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

use super::dispatcher::{Archive, Reaction};
use super::dispatcher::DApp as DAppTrait;
use super::dispatcher::{Bytes32Field, String32Field, U256Field};
use super::error::*;
use super::ethabi::Token;
use super::ethereum_types::{H256, U256};
use super::tournament::reveal_commit::{RevealCommit, RevealCommitCtx, RevealCommitCtxParsed};
use super::tournament::matchmanager::{MatchManager, MatchManagerCtx, MatchManagerCtxParsed};
use super::tournament::{cartesi_base, MachineTemplate};
use super::transaction;
use super::transaction::TransactionRequest;

pub struct DApp();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
pub struct DAppCtxParsed(
    U256Field,     // level
    Bytes32Field,  // setupHash
    U256Field,     // finalTime
    String32Field, // currentState
);

#[derive(Serialize, Debug)]
pub struct DAppCtx {
    pub level: U256,
    pub setup_hash: H256,
    pub final_time: U256,
    pub current_state: String,
}

impl From<DAppCtxParsed> for DAppCtx {
    fn from(parsed: DAppCtxParsed) -> DAppCtx {
        DAppCtx {
            level: parsed.0.value,
            setup_hash: parsed.1.value,
            final_time: parsed.2.value,
            current_state: parsed.3.value,
        }
    }
}

impl DAppTrait<()> for DApp {
    /// React to the DApp contract, WaitingCommitAndReveal/WaitingMatches/DAppFinished
    fn react(
        instance: &state::Instance,
        archive: &Archive,
        post_action: &Option<String>,
        _: &(),
    ) -> Result<Reaction> {
        // get context (state) of the DApp instance
        let parsed: DAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse dapp instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: DAppCtx = parsed.into();
        trace!("Context for dapp (index {}) {:?}", instance.index, ctx);

        match ctx.current_state.as_ref() {
            "DAppFinished" => {
                return Ok(Reaction::Idle);
            }
            "WaitingCommitAndReveal" => {
                // we inspect the reveal contract
                let reveal_instance = instance.sub_instances.get(0).ok_or(Error::from(
                    ErrorKind::InvalidContractState(format!(
                        "There is no reveal instance {}",
                        ctx.current_state
                    )),
                ))?;

                let reveal_parsed: RevealCommitCtxParsed =
                    serde_json::from_str(&reveal_instance.json_data).chain_err(|| {
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
                        data: vec![Token::Uint(instance.index)],
                        gas: None,
                        strategy: transaction::Strategy::Simplest,
                    };

                    return Ok(Reaction::Transaction(request));
                }
                let machine_request = build_machine(false, instance.index, ctx.level)
                    .chain_err(|| format!("could not build machine message"))?;
                let opponent_machine_request =
                    build_machine(true, instance.index, ctx.level).chain_err(|| format!("could not build machine message"))?;
                let machine_template: MachineTemplate = MachineTemplate {
                    machine: machine_request.clone(),
                    opponent_machine: opponent_machine_request,
                    tournament_index: instance.index,
                    page_log2_size: 10,
                    tree_log2_size: 20,
                    final_time: ctx.final_time.as_u64(),
                };

                // if reveal is still active, pass control
                return RevealCommit::react(
                    reveal_instance,
                    archive,
                    post_action,
                    &machine_template,
                );
            }
            "WaitingMatches" => {
                // we inspect the match manager contract
                let match_manager_instance = instance.sub_instances.get(1).ok_or(Error::from(
                    ErrorKind::InvalidContractState(format!(
                        "There is no match manager instance {}",
                        ctx.current_state
                    )),
                ))?;

                let match_manager_parsed: MatchManagerCtxParsed = serde_json::from_str(&match_manager_instance.json_data)
                .chain_err(|| {
                    format!(
                        "Could not parse match manager instance json_data: {}",
                        &match_manager_instance.json_data
                    )
                })?;
                let match_manager_ctx: MatchManagerCtx = match_manager_parsed.into();
                
                if match_manager_ctx.current_state == "MatchesOver" {
                    let request = TransactionRequest {
                        concern: instance.concern.clone(),
                        value: U256::from(0),
                        function: "claimFinished".into(),
                        data: vec![Token::Uint(instance.index)],
                        gas: None,
                        strategy: transaction::Strategy::Simplest,
                    };

                    return Ok(Reaction::Transaction(request));
                }

                let machine_request = build_machine(false, instance.index, ctx.level)
                    .chain_err(|| format!("could not build machine message"))?;
                let opponent_machine_request =
                    build_machine(true, instance.index, ctx.level).chain_err(|| format!("could not build machine message"))?;
                let machine_template: MachineTemplate = MachineTemplate {
                    machine: machine_request.clone(),
                    opponent_machine: opponent_machine_request,
                    tournament_index: instance.index,
                    page_log2_size: 10,
                    tree_log2_size: 20,
                    final_time: ctx.final_time.as_u64(),
                };

                return MatchManager::react(
                    match_manager_instance,
                    archive,
                    &None,
                    &machine_template,
                );
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
        let parsed: DAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse arbitration test instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: DAppCtx = parsed.into();
        let json_data = serde_json::to_string(&ctx).unwrap();

        // get context (state) of the sub instances

        let mut pretty_sub_instances: Vec<Box<state::Instance>> = vec![];

        pretty_sub_instances.push(Box::new(
            RevealCommit::get_pretty_instance(
                instance.sub_instances.get(0).unwrap(),
                archive,
                &Default::default(),
            )
            .unwrap(),
        ));

        if instance.sub_instances.len() > 1 {
            pretty_sub_instances.push(Box::new(
                MatchManager::get_pretty_instance(
                    instance.sub_instances.get(1).unwrap(),
                    archive,
                    &Default::default(),
                )
                .unwrap(),
            ));
        }

        let pretty_instance = state::Instance {
            name: "DApp".to_string(),
            concern: instance.concern.clone(),
            index: instance.index,
            json_data: json_data,
            sub_instances: pretty_sub_instances,
        };

        return Ok(pretty_instance);
    }
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// below are the codes to generate hard-coded new machine request
// may need to revise in the future
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


fn bootargs() -> String {
    format!(
        "console=hvc0 rootfstype=ext2 root=/dev/mtdblock0 rw {} -- /mnt/creepts/bin/verify",
        "mtdparts=flash.0:-(root);flash.1:-(creepts);flash.2:-(log);flash.3:-(level);flash.4:-(output)",
    )
}

fn emulator_file_path() -> String {
    "/opt/cartesi/srv/emulator-files/".to_string()
}
fn dapp_data_path() -> String {
    "/opt/cartesi/srv/creepts/".to_string()
}

fn backing(path: String, filename: String) -> String {
    format!("{}{}", path, filename)
}
fn level_backing(path: String, level: U256) -> String {
    format!("{}{}.bin", path, level)
}
fn log_backing(path: String, index: U256, is_opponent: bool) -> String {
    if is_opponent {
        format!("{}{}_opponent.json.br.cpio", path, index)
    } else {
        format!("{}{}.json.br.cpio", path, index)
    }
}

struct Ram {
    length: u64,
    backing: String,
}

struct Rom {
    bootargs: String,
    backing: String,
}

struct Drive {
    backing: String,
    shared: bool,
    label: String,
    start: u64,
    length: u64,
}

fn test_drives(is_opponent: bool, index: U256, level: U256) -> [Drive; 5] {
    [
        Drive {
            backing: backing(emulator_file_path(), "rootfs.ext2".to_string()),
            shared: false,
            label: "root".to_string(),
            start: 0x8000000000000000,
            length: 0x3c00000,
        },
        Drive {
            backing: backing(emulator_file_path(), "creeptsfs.ext2".to_string()),
            shared: false,
            label: "creepts".to_string(),
            start: 0xa000000000000000,
            length: 0x2800000,
        },
        Drive {
            backing: log_backing(dapp_data_path(), U256::from(index), is_opponent),
            shared: false,
            label: "log".to_string(),
            start: 0xc000000000000000,
            length: 0x100000,
        },
        Drive {
            backing: level_backing(emulator_file_path(), U256::from(level)),
            shared: false,
            label: "level".to_string(),
            start: 0xd000000000000000,
            length: 0x1000,
        },
        Drive {
            backing: backing(emulator_file_path(), "output.bin".to_string()),
            shared: false,
            label: "output".to_string(),
            start: 0xe000000000000000,
            length: 0x1000,
        }
    ]
}

fn test_rom() -> Rom {
    Rom {
        bootargs: bootargs(),
        backing: backing(emulator_file_path(), "rom.bin".to_string())
    }
}

fn test_ram() -> Ram {
    Ram {
        length: 512 << 20,
        backing: backing(emulator_file_path(), "kernel.bin".to_string())
    }
}

fn build_machine(is_opponent: bool, index: U256, level: U256) -> Result<cartesi_base::MachineRequest> {
    let mut ram_msg = cartesi_base::RAM::new();
    let test_ram = test_ram();
    ram_msg.set_length(test_ram.length);
    ram_msg.set_backing(test_ram.backing);

    let mut drives_msg: Vec<cartesi_base::Drive> = Vec::new();

    let drives = test_drives(is_opponent, index, level);

    for drive in drives.iter() {
        let mut drive_msg = cartesi_base::Drive::new();

        drive_msg.set_start(drive.start);
        drive_msg.set_length(drive.length);
        drive_msg.set_backing(drive.backing.clone());
        drive_msg.set_label(drive.label.clone());
        drive_msg.set_shared(drive.shared);

        drives_msg.push(drive_msg);
    }

    let mut rom_msg = cartesi_base::ROM::new();
    let test_rom = test_rom();
    rom_msg.set_bootargs(test_rom.bootargs);
    rom_msg.set_backing(test_rom.backing);

    let mut machine = cartesi_base::MachineRequest::new();
    machine.set_rom(rom_msg);
    machine.set_ram(ram_msg);
    machine.set_flash(protobuf::RepeatedField::from_vec(drives_msg));

    trace!("Build machine for dapp (index {}, level {}) {:?}", index, level, machine);

    return Ok(machine);
}
