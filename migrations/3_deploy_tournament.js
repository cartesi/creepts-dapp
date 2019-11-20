const fs = require('fs');


var RevealInstantiator = artifacts.require("@cartesi/tournament/RevealInstantiator");
var BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");
var MatchManagerInstantiator = artifacts.require("@cartesi/tournament/MatchManagerInstantiator");
var MatchInstantiator = artifacts.require("@cartesi/tournament/MatchInstantiator");
var Logger = artifacts.require("@cartesi/logger/Logger");

var LoggerMock = artifacts.require("@cartesi/tournament/LoggerMock");

var VGMock = artifacts.require("@cartesi/tournament/VGMock");
var RevealMock = artifacts.require("@cartesi/tournament/RevealMock");
var DAppMock = artifacts.require("@cartesi/tournament/DAppMock");

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {
        await deployer.deploy(BitsManipulationLibrary);
        await deployer.link(BitsManipulationLibrary, RevealInstantiator);

        await deployer.deploy(Logger);
        await deployer.deploy(VGMock);
        await deployer.deploy(LoggerMock);

        await deployer.deploy(MatchInstantiator, VGMock.address);
        await deployer.deploy(MatchManagerInstantiator, MatchInstantiator.address);

        // TO-DO: Should deploy with real Logger, not LoggerMock
        //await deployer.deploy(RevealInstantiator, Logger.address);

        // THIS IS JUST FOR TESTING PURPOSES
        await deployer.deploy(RevealInstantiator, LoggerMock.address);

        // add main "player" values here before adding other accounts
        var playerAddresses = [accounts[0]];
        var scores = [100];
        var finalHashes = ["0x01"];
        var logHashes = ["0x00"];
        var initialHashes = ["0x00"];

        for (var i = 1; i < accounts.length; i++) {
            playerAddresses.push(accounts[i]);
            scores.push(i * 20);
            logHashes.push("0x00");
            initialHashes.push("0x00");
            finalHashes.push("0x00");
        }

        await deployer.deploy(RevealMock, MatchManagerInstantiator.address);
        await deployer.deploy(DAppMock, RevealMock.address, playerAddresses, scores, logHashes, initialHashes, finalHashes);

        // TO-DO: Shouldnt be logger_mock, should be actual logger
        // Write address to file
        let addr_json = "{\"ri_address\":\"" + RevealInstantiator.address + "\", \"logger_mock_address\":\"" + LoggerMock.address + "\"}";

        fs.writeFile('../test/deployedAddresses.json', addr_json, (err) => {
          if (err) console.log("couldnt write to file");
        });

    });

};

