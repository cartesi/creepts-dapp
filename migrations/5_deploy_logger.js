const Logger = artifacts.require("@cartesi/logger/Logger");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(Logger);
};
