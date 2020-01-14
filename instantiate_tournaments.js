const contract = require("@truffle/contract");

const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));
const Step = contract(require("@cartesi/machine-solidity-step/build/contracts/Step.json"));
const DApp = contract(require("./build/contracts/DApp.json"));

module.exports = async (callback) => {

    try {
        const networkId = await web3.eth.net.getId();
        const accounts = await web3.eth.personal.getAccounts();
        const fromAddress = accounts[0];

        const contracts = [
            MatchManagerInstantiator,
            RevealInstantiator,
            Step,
            DApp
        ];
        contracts.forEach(contract => {
            contract.setNetwork(networkId);
            contract.setProvider(web3.currentProvider);
            console.log(`${contract.contract_name} => ${contract.address}`);
        });

        const commitDuration = 200;
        const scoreDriveLogSize = 3;
        const logDriveLogSize = 20;
        const epochDuration = 200;
        const matchDuration = 90;
        const roundDuration = 45;
        const finalTime = 1e13;

        var setupHashes = [
            "0x83a2b88934ac816c45e810b1c4344b214f88ccc7ecc9b5917cf6051b789974dd",
            "0xdb886e23cce224acb75ae42bdebe44bbf07a3eca51a6629043d1e4e6518a42cb",
            "0x425b43d06f55cce660a04bd4b605536f13fb6dab5072f5ce62f3527e02db8718",
            "0xa236a1fc9b5c31ef0d02801c1f00cc84e1d8afd0433797e201b5044676a39108",
            "0xa7700ff2f7e37ef8ade81d66926373688960812568485e4deecf02598b57e2b9",
            "0x367d8064182ac7e32c33604cf1c77bbabea8c1810f9d3007414d1bdcfda11196",
            "0xcd6bdaba99ef44c205ffa08f5c78d043d40a45ecd0ee54f94fb8865a3d6ddd37",
            "0xbc221d51b0d9c024e0d2bb9067ad42907b17da6e916d20eab2d538561044db4"
        ];

        const dapp = await DApp.deployed();
        for (var i in setupHashes) {
            const hash = setupHashes[i];
            const transaction = await dapp.instantiate(
                RevealInstantiator.address,
                MatchManagerInstantiator.address,
                commitDuration,
                scoreDriveLogSize,
                logDriveLogSize,
                hash,
                i, // level
                epochDuration,
                matchDuration,
                roundDuration,
                finalTime,
                Step.address,
                { from: fromAddress }
            );
            console.log(`Tournament ${i} created: ${transaction.tx}`);
        }

        callback();

    } catch (e) {
        console.error(e);
        callback(e);
    }
};
