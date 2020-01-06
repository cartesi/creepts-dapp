const contract = require("@truffle/contract");

const PartitionInstantiator = contract(require("@cartesi/arbitration/build/contracts/PartitionInstantiator.json"));
const MMInstantiator = contract(require("@cartesi/arbitration/build/contracts/MMInstantiator.json"));
const VGInstantiator = contract(require("@cartesi/arbitration/build/contracts/VGInstantiator.json"));
const ComputeInstantiator = contract(require("@cartesi/arbitration/build/contracts/ComputeInstantiator.json"));
const MatchInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchInstantiator.json"));
const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));

const DApp = artifacts.require("DApp");
const CreeptsDApp = artifacts.require("CreeptsDApp");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {

        const contracts = [
            PartitionInstantiator,
            MMInstantiator,
            VGInstantiator,
            ComputeInstantiator,
            MatchInstantiator,
            MatchManagerInstantiator,
            RevealInstantiator,
            DApp
        ];
        
        // set network_id explicitily so address can be resolved
        contracts.forEach(contract => contract.setNetwork(deployer.network_id));

        if (deployer.ens) {
            if (network == 'rinkeby') {
                const domain = 'creepts.cartesi.test';
                
                for (const contract of contracts) {
                    const fqdn = `${contract.contractName}.${domain}`;
                    console.log(`Registering '${contract.address}' to '${fqdn}', from ${accounts[0]}`);
                    await deployer.ens.setAddress(fqdn, contract.address, { from: accounts[0] });
                }
                
                console.log(`Registering '${CreeptsDApp.address}' to '${domain}', from ${accounts[0]}`);
                await deployer.ens.setAddress(domain, CreeptsDApp.address, { from: accounts[0] });
            }
        }
    });
};
