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
    .option('--reveal-duration <duration>', 'Duration in seconds of reveal phase', 200)
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
        const revealDuration = program.revealDuration;
        const matchDuration = program.matchDuration;
        const roundDuration = program.roundDuration;
        const scoreDriveLogSize = 3;
        const logDriveLogSize = 20;
        const finalTime = 1e13;

        const setupHashes = [
            "0x6439c6bd5880b7976d7c01cf1381228070103f147852f125c02dca3e1340c2e3",
            "0xae3a63dd47908b000b9b94feae42b446e2baaa7c5f9449c000f72498ef5b78d9",
            "0xf362e94341bfa35d7bd9f9bbf3a20ae5108bed4693172792bf762f30a73d2e31",
            "0x3cb9f524445392cae8f5a8b68a38f91c391d3bd0dd3c55b36cde9ae4189113a7",
            "0x54edd98b2ae5f7cc319948f1a693de8ddf3bee353670783ce52e276ed3d564e7",
            "0x5abd9e7378a4bfc852a4e9170cf94e1ee209dc8b9ba843eb449ca2418417aa40",
            "0x7949eab66a11579d617aca17862bdf643300f06d5e5f232effafdda716491bc0",
            "0x726757b2b7cbe4da87cedfebd70a62cd654253a4d24e37af4e0bc58f52a1651a"
        ];

        const dapp = await DApp.deployed();
        const hash = setupHashes[program.level];
        const transaction = await dapp.instantiate(
            RevealInstantiator.address,
            MatchManagerInstantiator.address,
            commitDuration,
            revealDuration,
            scoreDriveLogSize,
            logDriveLogSize,
            hash,
            program.level,
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
