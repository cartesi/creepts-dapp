/**
 * Truffle script to create new tornaments.
 * 
 * Usage:
 * truffle exec <script> --network <network> --level <level> --commit-duration <duration>
 */

const contract = require("@truffle/contract");
const program = require("commander");

const MatchManagerInstantiator = contract(require("@cartesi/tournament/build/contracts/MatchManagerInstantiator.json"));
const RevealInstantiator = contract(require("@cartesi/tournament/build/contracts/RevealInstantiator.json"));
const Step = contract(require("@cartesi/machine-solidity-step/build/contracts/Step.json"));
const DApp = contract(require("./build/contracts/DApp.json"));

program
    .option('-n, --network <network>', 'Specify the network to use, using artifacts specific to that network. Network name must exist in the configuration')
    .option('-c, --compile', 'Compile contracts before executing the script')
    .option('-l, --level <level>', 'Level number [0-7]', 0)
    .option('--commit-duration <duration>', 'Duration in seconds of commit phase', 200)
    .option('--epoch-duration <duration>', 'Duration in seconds of epoch phase', 200)
    .option('--match-duration <duration>', 'Duration in seconds of match phase', 90)
    .option('--round-duration <duration>', 'Duration in seconds of round phase', 45);

module.exports = async (callback) => {

    program.parse(process.argv);
    console.log(`Creating tournament for level ${program.level} with commit duration of ${program.commitDuration} seconds`);

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

        const commitDuration = program.commitDuration;
        const epochDuration = program.epochDuration;
        const matchDuration = program.matchDuration;
        const roundDuration = program.roundDuration;
        const scoreDriveLogSize = 3;
        const logDriveLogSize = 20;
        const finalTime = 1e13;

        const setupHashes = [
            "0x42c87a7ef46cd76687023fa4410e197d1a0b340f8022b6717e7bd7b6b8b6150b",
            "0x67b7effefed2d306b796f7d0c478e75b976294506cf5d73d162f8553de13f0de",
            "0x267316e8496c4297e65b3c494cc28f5df5f0c722c7d38916988ba4da48046149",
            "0xdd8362b010474f23ce6e67d4acc8bf0773864e1841b973cb62c1c316e9001d6d",
            "0x4060f319fd067a0e60a921b9e74e9c157c0f0590198f277c1cdf9cad4ee2b007",
            "0x2847ec8110bc1001bc34069a9466f8e1fbe668b6d07278aced4a66b153742a12",
            "0xa9f0efa1e827d24beb86b04944539a77bf40dfca03f22c821c619c1bd712acb1",
            "0xb21a49e03da0b85fb2a295a3e8f73947113bb91f01596613e90514b56786dc70"
        ];

        const dapp = await DApp.deployed();
        const hash = setupHashes[program.level];
        const transaction = await dapp.instantiate(
            RevealInstantiator.address,
            MatchManagerInstantiator.address,
            commitDuration,
            scoreDriveLogSize,
            logDriveLogSize,
            hash,
            program.level,
            epochDuration,
            matchDuration,
            roundDuration,
            finalTime,
            Step.address,
            { from: fromAddress }
        );
        console.log(`Tournament created: ${transaction.tx}`);
        callback();

    } catch (e) {
        console.error(e);
        callback(e);
    }
};
