const Logger = artifacts.require("@cartesi/logger/Logger");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.deploy(Logger);
    });
};

