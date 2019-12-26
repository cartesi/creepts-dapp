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
