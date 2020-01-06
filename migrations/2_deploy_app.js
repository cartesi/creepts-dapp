const contract = require("@truffle/contract");
const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));
const Step = contract(require("@cartesi/machine-solidity-step/build/contracts/Step.json"));

const DApp = artifacts.require("DApp");

module.exports = function(deployer, network, accounts) {
    // !!! setupHash should be modified manually in the CreeptsDApp contract !!!
    deployer.then(async () => {
        MatchManagerInstantiator.setNetwork(deployer.network_id);
        RevealInstantiator.setNetwork(deployer.network_id);
        Step.setNetwork(deployer.network_id);

        await deployer.deploy(DApp);
};
