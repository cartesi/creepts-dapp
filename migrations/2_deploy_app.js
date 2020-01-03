const contract = require("@truffle/contract");
const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));
const Step = contract(require("@cartesi/machine-solidity-step/build/contracts/Step.json"));

const DApp = artifacts.require("DApp");
const CreeptsDApp = artifacts.require("CreeptsDApp");

module.exports = function(deployer, network, accounts) {
    // !!! setupHash should be modified manually in the CreeptsDApp contract !!!
    deployer.then(async () => {
        MatchManagerInstantiator.setNetwork(deployer.network_id);
        RevealInstantiator.setNetwork(deployer.network_id);
        Step.setNetwork(deployer.network_id);

        await deployer.deploy(DApp);
        await deployer.deploy(
            CreeptsDApp,
            DApp.address, //dappAddress
            RevealInstantiator.address, //rmAddress,
            MatchManagerInstantiator.address, //mmAddress,
            200, //commitDuration,
            3, //scoreDriveLogSize,
            20, //logDriveLogSize,
            //setupHash: HAS TO BE ADDED DIRECTLY IN test/DAppManager.sol
            0, //level,
            100, //epochDuration,
            150, //matchDuration,
            25, //roundDuration,
            1e13, //finalTime,
            Step.address //machineAddress
        );
    });

};
