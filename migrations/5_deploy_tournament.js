const fs = require('fs');

var RevealInstantiator = artifacts.require("@cartesi/tournament/RevealInstantiator");
var BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");
var MatchManagerInstantiator = artifacts.require("@cartesi/tournament/MatchManagerInstantiator");
var MatchInstantiator = artifacts.require("@cartesi/tournament/MatchInstantiator");

const Logger = artifacts.require("@cartesi/logger/Logger");

const VGInstantiator = artifacts.require("@cartesi/arbitration/VGInstantiator");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.deploy(BitsManipulationLibrary);
        await deployer.link(BitsManipulationLibrary, RevealInstantiator);

        await deployer.deploy(VGMock);

        await deployer.deploy(MatchInstantiator, VGInstantiator.address);
        await deployer.deploy(MatchManagerInstantiator, MatchInstantiator.address);

        await deployer.deploy(RevealInstantiator, Logger.address);
    });
};

