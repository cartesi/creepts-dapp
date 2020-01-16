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
            "0x865499c9c9b63cbd85152c7e2e2a14a3b195be1d91787cf99a7bf4fb39a5882d",
            "0xd3c9fd9c6d88a2df501f561f49639e936c6e10df546422448ce169b61bffeda4",
            "0x2765fbc1a3c324f8f79c5bbf4a7811c1b0d86e898dd3a798d5a313f60d12c49b",
            "0x073c5f068671cec95c102abccc48257feb8bdeeee8e141de8836dd23a8ff818e",
            "0xf622c793c73271c4510c1fd2ca7eaad88ab98f826d4ad96a62f4bcfe8983e064",
            "0xaecc41f597ce71af0781b68bb16ffc78be44b455d6807ad530cf6516ae9480e9",
            "0x1e9965749efe399ccdc48b7e249c0912d35dba04efdcd6a0268cf5cb329f68e4",
            "0x4d5e3cacd0baf9a439ea97958fe299c51caf61dedde3d60e517018bab0d302ca"
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
