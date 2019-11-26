const BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(BitsManipulationLibrary);
};
