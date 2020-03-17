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
    .option('-a, --account <account>', 'Account sender of transaction')
    .option('--commit-duration <duration>', 'Duration in seconds of commit phase', 200)
    .option('--reveal-duration <duration>', 'Duration in seconds of reveal phase', 200)
    .option('--round-duration <duration>', 'Duration in seconds of round phase', 45);

module.exports = async (callback) => {

    program.parse(process.argv);
    console.log(`Creating tournament for level ${program.level} with commit duration of ${program.commitDuration} seconds`);

    try {
        const networkId = await web3.eth.net.getId();

        let fromAddress = undefined;
        if (program.account) {
            fromAddress = program.account;
        } else {
            const accounts = await web3.eth.personal.getAccounts();
            fromAddress = accounts[0];
        }

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
        const roundDuration = program.roundDuration;
        const scoreDriveLogSize = 3;
        const logDriveLogSize = 20;
        const finalTime = 1e13;

        const setupHashes = [
            "0x375fb938dcff562818779bc0dc4689a713a61d89659c8a9274a53551c7bc464c",
            "0xb58562a821fd887ee508da7bc0926ce75a461ebd45d35c8e1ed7caa906559e5c",
            "0x5dde12fc07c72c146848be21c85c13071630b59c8dc915d46e0f4528eaf45111",
            "0x37edf1fda365aa316374aed600b4bc7b981ab9cb7952b6f0e68bb362f93abd0d",
            "0xefe6f44a51e45045e50dcb1fcd1388a550b822ad9b2bdf4ccef01292720c02c4",
            "0x1e9b8a93e65a51509dcab1c1444d0fc7deb14589972bf58ca6708a56aca0ef3b",
            "0x2098fbf4c6a46e0586a55def8229f8ef5c5972c6032fcb344f9b434be4e5a4a7",
            "0x872f44b8a31938ceacfbd7d537de344fc0a5657a26b8e15276324a1d73cd420b"
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
