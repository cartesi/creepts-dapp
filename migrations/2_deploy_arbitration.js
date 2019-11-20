
const PartitionInstantiator = artifacts.require("@cartesi/arbitration/PartitionInstantiator");
const SimpleMemoryInstantiator = artifacts.require("@cartesi/arbitration/SimpleMemoryInstantiator");
const MMInstantiator = artifacts.require("@cartesi/arbitration/MMInstantiator");
const VGInstantiator = artifacts.require("@cartesi/arbitration/VGInstantiator");
const Hasher = artifacts.require("@cartesi/arbitration/Hasher");
const ComputeInstantiator = artifacts.require("@cartesi/arbitration/ComputeInstantiator");

const PartitionTestAux = artifacts.require("@cartesi/arbitration/PartitionTestAux");
const MMInstantiatorTestAux = artifacts.require("@cartesi/arbitration/MMInstantiatorTestAux");
const TestHash = artifacts.require("@cartesi/arbitration/TestHash");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.deploy(SimpleMemoryInstantiator);
        await deployer.deploy(PartitionInstantiator);
        await deployer.deploy(MMInstantiator);

        await deployer.deploy(VGInstantiator, PartitionInstantiator.address, MMInstantiator.address);
        await deployer.deploy(Hasher, MMInstantiator.address);

        await deployer.deploy(ComputeInstantiator, VGInstantiator.address);

        await deployer.deploy(PartitionTestAux);
        await deployer.deploy(MMInstantiatorTestAux);
        await deployer.deploy(TestHash);
    });
};
