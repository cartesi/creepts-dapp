const fs = require('fs');

var DApp = artifacts.require("DApp");

var DAppManager = artifacts.require("DAppManager");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.deploy(DApp);
        await deployer.deploy(
            DAppManager,
            DApp.address, //dappAddress
            DApp.address, //rmAddress,
            DApp.address, //mmAddress,
            200, //commitDuration,
            200, //revealDuration,
            (1<<63)+(3<<61), //scoreWordPosition,
            (1<<63)+(2<<61), //logDrivePosition,
            3, //scoreDriveLogSize,
            20, //logDriveLogSize,
            "0x00", //setupHash,
            "0x00", //tournamentName,
            100, //epochDuration,
            50, //matchDuration,
            25, //roundDuration,
            100000, //finalTime,
            DApp.address //machineAddress
        );
    });

};

