
const BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");
const Logger = artifacts.require("@cartesi/logger/Logger");
const VGInstantiator = artifacts.require("@cartesi/arbitration/VGInstantiator");

const RevealInstantiator = artifacts.require("@cartesi/tournament/RevealInstantiator");
const MatchManagerInstantiator = artifacts.require("@cartesi/tournament/MatchManagerInstantiator");
const MatchInstantiator = artifacts.require("@cartesi/tournament/MatchInstantiator");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.link(BitsManipulationLibrary, RevealInstantiator);
        await deployer.deploy(MatchInstantiator, VGInstantiator.address);
        await deployer.deploy(MatchManagerInstantiator, MatchInstantiator.address);
        await deployer.deploy(RevealInstantiator, Logger.address);
    });
};
