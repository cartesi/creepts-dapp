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
            "0x3ef7d168aa4ae54ae166e1b857b9d46eec9d568d05d305c0101879963c734d25",
            "0xddffddc238e4862eb41196525cd7e61275dfc32c98c769f8d45ed62439cb0d17",
            "0xf7e089a1849dc1f06f35e9c6b37a8f71eaa9082abe729e24ac653127bf454370",
            "0x4657d5d1c2d2af542dc538d6f69f0674d40dfa340e26f67dc49428b795a5b7ce",
            "0x5096bf3c0d5d2257aeddaa4620d6b23aff381aa2fc26e5a83751a4443f6eee2c",
            "0x01975e53074454076a37baca511eccff3d3bb06c1a43b2cd46f8cebb3ab0fc91",
            "0x9179c6d12af099e5b53816b500692b1d55c85f22942c5d0b2e3e879ed0e548a5",
            "0x9a5d4f2745e18df93eeb3ecaf613cf728f84ad2d34a4b822ed6664e24925a6c9"
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
