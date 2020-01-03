use super::dapp::{DApp, DAppCtx, DAppCtxParsed};
use super::dispatcher::{Archive, Reaction};
use super::dispatcher::DApp as DAppTrait;
use super::dispatcher::{String32Field, U256Field};
use super::error::Result;
use super::error::*;
use super::ethabi::Token;
use super::ethereum_types::U256;
use super::transaction;
use super::transaction::TransactionRequest;
use super::tournament::{Payload, Params};

pub struct CreeptsDApp();

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// these two structs and the From trait below shuld be
// obtained from a simple derive
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#[derive(Serialize, Deserialize)]
struct CreeptsDAppCtxParsed(
    U256Field,     // dappIndex
    String32Field, // currentState
);

#[derive(Serialize, Debug)]
struct CreeptsDAppCtx {
    dapp_index: U256,
    current_state: String,
}

impl From<CreeptsDAppCtxParsed> for CreeptsDAppCtx {
    fn from(parsed: CreeptsDAppCtxParsed) -> CreeptsDAppCtx {
        CreeptsDAppCtx {
            dapp_index: parsed.0.value,
            current_state: parsed.1.value,
        }
    }
}

impl DAppTrait<()> for CreeptsDApp {
    /// React to the DApp contract, submitting solutions, confirming
    /// or challenging them when appropriate
    fn react(
        instance: &state::Instance,
        archive: &Archive,
        _post_payload: &Option<String>,
        _: &(),
    ) -> Result<Reaction> {
        // get context (state) of the compute instance
        let parsed: CreeptsDAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse compute instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: CreeptsDAppCtx = parsed.into();
        trace!("Context for mockDApp (index {}) {:?}", instance.index, ctx);

        // these states should not occur as they indicate an innactive instance,
        // but it is possible that the blockchain state changed between queries
        match ctx.current_state.as_ref() {
            "DAppFinished" => {
                return Ok(Reaction::Terminate);
            }

            "Idle" => {
                println!("STATE is IDLE");
                let request = TransactionRequest {
                    concern: instance.concern.clone(),
                    value: U256::from(0),
                    function: "claimDAppRunning".into(),
                    data: vec![Token::Uint(instance.index)],
                    gas: None,
                    strategy: transaction::Strategy::Simplest,
                };

                return Ok(Reaction::Transaction(request));
            }

            "DAppRunning" => {
                // we inspect the dapp contract
                let dapp_instance = instance.sub_instances.get(0).ok_or(Error::from(
                    ErrorKind::InvalidContractState(format!(
                        "There is no dapp instance {}",
                        ctx.current_state
                    )),
                ))?;

                let dapp_parsed: DAppCtxParsed =
                    serde_json::from_str(&dapp_instance.json_data).chain_err(|| {
                        format!(
                            "Could not parse dapp instance json_data: {}",
                            &dapp_instance.json_data
                        )
                    })?;
                let dapp_ctx: DAppCtx = dapp_parsed.into();

                match dapp_ctx.current_state.as_ref() {
                    "DAppFinished" => {
                        // claim Finished in dappmock test contract
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
                    _ => {
                        // dapp is still active,
                        // pass control to the appropriate dapp
                        let param = Params {
                            hash: "fe7a808b870492a94337d0c3682a3030029d9f479a93c2b2d162f79638850d01".into()
                        };

                        let payload = Payload {
                            action: "commit".into(),
                            params: param
                        };

                        let payload_string = serde_json::to_string(&payload).unwrap();

                        return DApp::react(dapp_instance, archive, &Some(payload_string), &());
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
        let parsed: CreeptsDAppCtxParsed =
            serde_json::from_str(&instance.json_data).chain_err(|| {
                format!(
                    "Could not parse match instance json_data: {}",
                    &instance.json_data
                )
            })?;
        let ctx: CreeptsDAppCtx = parsed.into();
        let json_data = serde_json::to_string(&ctx).unwrap();

        // get context (state) of the sub instances

        let mut pretty_sub_instances: Vec<Box<state::Instance>> = vec![];

        for sub in &instance.sub_instances {
            pretty_sub_instances.push(Box::new(
                DApp::get_pretty_instance(sub, archive, &()).unwrap(),
            ))
        }

        let pretty_instance = state::Instance {
            name: "CreeptsDApp".to_string(),
            concern: instance.concern.clone(),
            index: instance.index,
            json_data: json_data,
            sub_instances: pretty_sub_instances,
        };

        return Ok(pretty_instance);
    }
}
