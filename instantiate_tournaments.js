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
            "0x85c88b74ac172e5754ecdc144d425248506a91aeddf7aa024a8c20da49bfbe33",
            "0x8b579a78a47d368f08e5c50e94064087ffa7501492741623a486ef10295a9fda",
            "0x5a4b9ea36dc37478372f977fb403069a0c1cfa458290ca1bf3f9f20a1cce44bc",
            "0x1c3cff019c0b748218dd20d49dbd5fcf8eea155ec70fefb57be6ffcf10abe7e0",
            "0xe510543f0cea0450c544a1bb8e0573c697782c7ead979a282a315ed904954d04",
            "0x6f9ac5f17a79fbb1978aadd24361c9c5c6a27bf7cf830c404980af6bb0bfa14e",
            "0x870d20185cb0310fd6f3c4a848a22afd98cf776457fc4d7aab7807d339186cdf",
            "0x001c13e01c09156c8d5e3a8d74978aa79f55624a81658cf38a6b89d620624041"
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
