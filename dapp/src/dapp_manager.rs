use super::anuto_dapp::{AnutoDApp, AnutoDAppCtx, AnutoDAppCtxParsed};
use super::dispatcher::{Archive, DApp, Reaction};
use super::dispatcher::{String32Field, U256Field};
use super::error::Result;
use super::error::*;
use super::ethabi::Token;
use super::ethereum_types::U256;
use super::transaction;
use super::transaction::TransactionRequest;
use super::tournament::{Payload, Params};

pub struct DAppManager();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
struct DAppManagerCtxParsed(
    U256Field,     // dappIndex
    String32Field, // currentState
);

#[derive(Serialize, Debug)]
struct DAppManagerCtx {
    dapp_index: U256,
    current_state: String,
}

impl From<DAppManagerCtxParsed> for DAppManagerCtx {
    fn from(parsed: DAppManagerCtxParsed) -> DAppManagerCtx {
        DAppManagerCtx {
            dapp_index: parsed.0.value,
            current_state: parsed.1.value,
        }
    }
}

impl DApp<()> for DAppManager {
    /// React to the DApp contract, submitting solutions, confirming
    /// or challenging them when appropriate
    fn react(
        instance: &state::Instance,
        archive: &Archive,
        _post_payload: &Option<String>,
        _: &(),
    ) -> Result<Reaction> {
        // get context (state) of the compute instance
        let parsed: DAppManagerCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse compute instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: DAppManagerCtx = parsed.into();
        trace!("Context for mockDApp (index {}) {:?}", instance.index, ctx);

        // these states should not occur as they indicate an innactive instance,
        // but it is possible that the blockchain state changed between queries
        match ctx.current_state.as_ref() {
            "DAppFinnished" => {
                return Ok(Reaction::Idle);
            }

            "Idle" => {
                println!("STATE is IDLE");
                let request = TransactionRequest {
                    concern: instance.concern.clone(),
                    value: U256::from(0),
                    function: "claimDAppRunning".into(),
                    data: vec![Token::Uint(instance.index)],
                    strategy: transaction::Strategy::Simplest,
                };

                return Ok(Reaction::Transaction(request));
            }

            "DAppRunning" => {
                // we inspect the anuto contract
                let anuto_instance = instance.sub_instances.get(0).ok_or(Error::from(
                    ErrorKind::InvalidContractState(format!(
                        "There is no anuto instance {}",
                        ctx.current_state
                    )),
                ))?;

                let anuto_parsed: AnutoDAppCtxParsed =
                    serde_json::from_str(&anuto_instance.json_data).chain_err(|| {
                        format!(
                            "Could not parse anuto instance json_data: {}",
                            &anuto_instance.json_data
                        )
                    })?;
                let anuto_ctx: AnutoDAppCtx = anuto_parsed.into();

                match anuto_ctx.current_state.as_ref() {
                    "DAppFinnished" => {
                        // claim Finished in dappmock test contract
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
                        // anuto is still active,
                        // pass control to the appropriate dapp
                        let param = Params {
                            hash: "2c6448d6c5ff9f1d3d13965c412606380006086d4160c40de53959482237e032".into()
                        };

                        let payload = Payload {
                            action: "commit".into(),
                            params: param
                        };

                        let payload_string = serde_json::to_string(&payload).unwrap();

                        return AnutoDApp::react(anuto_instance, archive, &Some(payload_string), &());
                    }
                }
            }
            _ => {
                return Ok(Reaction::Idle);
            }
        }
    }

    fn get_pretty_instance(
        instance: &state::Instance,
        archive: &Archive,
        _: &(),
    ) -> Result<state::Instance> {
        // get context (state) of the match instance
        let parsed: DAppManagerCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse match instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: DAppManagerCtx = parsed.into();
        let json_data = serde_json::to_string(&ctx).unwrap();

        // get context (state) of the sub instances

        let mut pretty_sub_instances: Vec<Box<state::Instance>> = vec![];

        for sub in &instance.sub_instances {
            pretty_sub_instances.push(Box::new(
                AnutoDApp::get_pretty_instance(sub, archive, &()).unwrap(),
            ))
        }

        let pretty_instance = state::Instance {
            name: "DAppManager".to_string(),
            concern: instance.concern.clone(),
            index: instance.index,
            json_data: json_data,
            sub_instances: pretty_sub_instances,
        };

        return Ok(pretty_instance);
    }
}
