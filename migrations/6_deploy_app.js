const DApp = artifacts.require("DApp");
const DAppManager = artifacts.require("DAppManager");
const MatchManagerInstantiator = artifacts.require("@cartesi/tournament/MatchManagerInstantiator");
const RevealInstantiator = artifacts.require("@cartesi/tournament/RevealInstantiator");
const Step = artifacts.require("@cartesi/machine-solidity-step/Step");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.deploy(DApp);
        await deployer.deploy(
            DAppManager,
            DApp.address, //dappAddress
            RevealInstantiator.address, //rmAddress,
            MatchManagerInstantiator.address, //mmAddress,
            200, //commitDuration,
            200, //revealDuration,
            (1<<63)+(3<<61), //scoreWordPosition,
            (1<<63)+(2<<61), //logDrivePosition,
            3, //scoreDriveLogSize,
            20, //logDriveLogSize,
            "0x00", //setupHash,
            "0x00", //tournamentName,
            100, //epochDuration,
            50, //matchDuration,
            25, //roundDuration,
            100000, //finalTime,
            Step.address //machineAddress
        );
    });

};
