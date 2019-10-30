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
use std::fs;

pub struct AnutoDApp();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
struct AnutoDAppCtxParsed(
    String32Field,  // name of the tournament
    Bytes32Field,  // setupHash
    String32Field // currentState
);

#[derive(Debug)]
struct AnutoDAppCtx {
    tournament_name: String,
    setup_hash: H256,
    current_state: String
}

impl From<AnutoDAppCtxParsed> for AnutoDAppCtx {
    fn from(parsed: AnutoDAppCtxParsed) -> AnutoDAppCtx {
        AnutoDAppCtx {
            tournament_name: parsed.0.value,
            setup_hash: parsed.1.value,
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


