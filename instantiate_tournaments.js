let fs = require("fs");
const contract = require("@truffle/contract");

const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));
const Step = contract(require("@cartesi/machine-solidity-step/build/contracts/Step.json"));


module.exports = async (config) => {
    var networkId = await web3.eth.net.getId();
    var accounts = await web3.eth.personal.getAccounts()

    var fromAddress = accounts[0];
    MatchManagerInstantiator.setNetwork(networkId)
    RevealInstantiator.setNetwork(networkId)
    Step.setNetwork(networkId)

    console.log(MatchManagerInstantiator.address);
    console.log(RevealInstantiator.address);
    try {
        console.log(DApp.address);
    } catch (e){
        console.log(e);
    }

    var commitDuration = 200;
    var scoreDriveLogSize = 3;
    var logDriveLogSize = 20;
    var epochDuration = 200;
    var matchDuration = 90;
    var roundDuration = 45;
    var finalTime = 1e13;

    var setupHashes = [
        "0x83a2b88934ac816c45e810b1c4344b214f88ccc7ecc9b5917cf6051b789974dd",
        "0xdb886e23cce224acb75ae42bdebe44bbf07a3eca51a6629043d1e4e6518a42cb",
        "0x425b43d06f55cce660a04bd4b605536f13fb6dab5072f5ce62f3527e02db8718",
        "0xa236a1fc9b5c31ef0d02801c1f00cc84e1d8afd0433797e201b5044676a39108",
        "0xa7700ff2f7e37ef8ade81d66926373688960812568485e4deecf02598b57e2b9",
        "0x367d8064182ac7e32c33604cf1c77bbabea8c1810f9d3007414d1bdcfda11196",
        "0xcd6bdaba99ef44c205ffa08f5c78d043d40a45ecd0ee54f94fb8865a3d6ddd37",
        "0xbc221d51b0d9c024e0d2bb9067ad42907b17da6e916d20eab2d538561044db4"]

    for (var i in setupHashes) {
        var receipt = await DApp.functions.instantiate(
            RevealInstantiator.address,
            MatchManagerInstantiator.address,
            commitDuration,
            scoreDriveLogSize,
            logDriveLogSize,
            setupHashes[i],
            i, // level
            epochDuration,
            matchDuration,
            roundDuration,
            finalTime,
            Step.address
        ).transact({'from': fromAddress, 'gas': 6283185})

        console.log(receipt);
    }
}


