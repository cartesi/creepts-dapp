
const PartitionInstantiator = artifacts.require("@cartesi/arbitration/PartitionInstantiator");
const MMInstantiator = artifacts.require("@cartesi/arbitration/MMInstantiator");
const VGInstantiator = artifacts.require("@cartesi/arbitration/VGInstantiator");
const ComputeInstantiator = artifacts.require("@cartesi/arbitration/ComputeInstantiator");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.deploy(PartitionInstantiator);
        await deployer.deploy(MMInstantiator);
        await deployer.deploy(VGInstantiator, PartitionInstantiator.address, MMInstantiator.address);
        await deployer.deploy(ComputeInstantiator, VGInstantiator.address);
    });
};
