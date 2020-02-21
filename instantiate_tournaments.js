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
    .option('--match-duration <duration>', 'Duration in seconds of match phase', 90)
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
        const matchDuration = program.matchDuration;
        const roundDuration = program.roundDuration;
        const scoreDriveLogSize = 3;
        const logDriveLogSize = 20;
        const finalTime = 1e13;

        const setupHashes = [
            "0x82920eb4317138b39b9d9333f7a768dbb24db7252e95400818e501fe6a2159c5",
            "0xb25482f3386492228e7e165391b5b9742e477d2e26dfd06b0958cdefd2764b66",
            "0x2afeff8cadb329da36f4c27feb1c7e8d14903bc3df730fc76c921ca42a76d7cf",
            "0xe7977082975a46000d7ab9de0dfe61363d86e36096e08d1970f0d60e063f3f31",
            "0x674788b3b9cad820af63ea18c266abdad02d580da3068d5caa3b550c3fa6681b",
            "0xcb9d832a375b70123450a511534d49e39f7d88f59fe04287790fc13b86baa1ab",
            "0x05bc18e7afb2cdac48b8433e63e1df95f2a7571cd06f9b30e669b06d1bbfbd8e",
            "0xeea5ae314cb94f2d0def960a867358c94fc277d63892a6da688c409bba356fc5"
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
