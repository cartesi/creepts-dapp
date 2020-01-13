const DApp = artifacts.require("DApp");

module.exports = function(deployer) {
    deployer.deploy(DApp);
};
