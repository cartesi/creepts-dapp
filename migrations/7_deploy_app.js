const MatchManagerInstantiator = artifacts.require("@cartesi/tournament/MatchManagerInstantiator");
const RevealInstantiator = artifacts.require("@cartesi/tournament/RevealInstantiator");
const Step = artifacts.require("@cartesi/machine-solidity-step/Step");

const DApp = artifacts.require("DApp");
const DAppManager = artifacts.require("DAppManager");

module.exports = function(deployer, network, accounts) {
    // !!! setupHash should be modified manually in the DAppManager contract !!!
    deployer.then(async () => {
        await deployer.deploy(DApp);
        await deployer.deploy(
            DAppManager,
            DApp.address, //dappAddress
            RevealInstantiator.address, //rmAddress,
            MatchManagerInstantiator.address, //mmAddress,
            200, //commitDuration,
            (1<<63)+(3<<61), //scoreWordPosition,
            (1<<63)+(2<<61), //logDrivePosition,
            3, //scoreDriveLogSize,
            20, //logDriveLogSize,
            0x2ef6909718e7962c48c93157e84d576461d7b6d3929348d838fa0270490172c5, //setupHash: proof_data["proofs"]["level_after_write"]["proof"]["root_hash"]
            0, //level,
            100, //epochDuration,
            50, //matchDuration,
            25, //roundDuration,
            1e13, //finalTime,
            Step.address //machineAddress
        );
    });

};
