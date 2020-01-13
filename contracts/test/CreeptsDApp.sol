/// @title CreeptsDApp
/// @author Felipe Argento
pragma solidity ^0.5.0;


import "@cartesi/util/contracts/Decorated.sol";
import "../DAppInterface.sol";

contract CreeptsDApp is Decorated, Instantiator {

    DAppInterface private dapp;

    enum state {
        Idle,
        DAppRunning,
        DAppFinished
    }

    struct CreeptsDAppCtx {
        uint256 dappIndex;
        address dappAddress;

        // RevealCommit vars
        address rmAddress;
        address mmAddress;
        uint256 commitDuration;
        uint256 scoreDriveLogSize;
        uint256 logDriveLogSize;
        bytes32 setupHash;
        uint256 level;

        // matchmanager
        uint256 epochDuration;
        uint256 matchDuration;
        uint256 roundDuration;
        uint256 finalTime;
        address machineAddress;

        state currentState;
    }

    mapping(uint256 => CreeptsDAppCtx) internal instance;
    bytes32[8] setupHashes = [
        bytes32(0xf9c235f4f0e2452bf9bb3ce229a4f79c5258a3618ee71bd77cd9caf3ef958be8),
        bytes32(0xb0f71cf19d45f957abe0268bf4ecff2c6be958cea9c738b44e9e9b8b957a5b94),
        bytes32(0xf62a857045aab2a0aa85511e8845b947bd2beb35ff1025f04f40b6840465f7dc),
        bytes32(0x0fb737748f2b95b86f3fd78c831f49d2299026c4e89c272b2d328d0fd3fcdf75),
        bytes32(0x2bb5d36961ba1f44b58f109ca5f8aca6d9bd9f9e1fc5a2f302940e2b451caf35),
        bytes32(0x6564198bdfa1662f741b5368bcd017f3096b67b6b6708c6a00ed0e8a8f04331c),
        bytes32(0xc1a06d41e1e9508c112546844149849d736498d6453a18e330f1e41063c80222),
        bytes32(0x398fe6bb3c3892cddec597b4daa8fab01b5a71c74b2b3692f70476de15be9ed2)
    ];

    constructor(
        address _dappAddress,
        address _rmAddress,
        address _mmAddress,
        uint256 _commitDuration,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        uint256 _level,

        uint256 _epochDuration,
        uint256 _matchDuration,
        uint256 _roundDuration,
        uint256 _finalTime,
        address _machineAddress
    ) public {
        require(_level < 8, "Invalid level (0~7)");

        dapp = DAppInterface(_dappAddress);

        currentIndex = 0;

        instance[currentIndex].rmAddress = _rmAddress;
        instance[currentIndex].mmAddress = _mmAddress;
        instance[currentIndex].commitDuration = _commitDuration;
        instance[currentIndex].scoreDriveLogSize = _scoreDriveLogSize;
        instance[currentIndex].logDriveLogSize = _logDriveLogSize;
        instance[currentIndex].level = _level;
        instance[currentIndex].epochDuration = _epochDuration;
        instance[currentIndex].matchDuration = _matchDuration;
        instance[currentIndex].roundDuration = _roundDuration;
        instance[currentIndex].finalTime = _finalTime;
        instance[currentIndex].machineAddress = _machineAddress;

        instance[currentIndex].currentState = state.Idle;

        active[currentIndex] = true;

        currentIndex++;

    }

    function claimDAppRunning(uint256 _index) public {
        CreeptsDAppCtx memory i = instance[_index];
        require(i.currentState == state.Idle, "State has to be Idle");

        instance[_index].currentState = state.DAppRunning;

        // !!! setupHash should be modified manually in the CreeptsDApp contract !!!
        instance[_index].dappIndex = dapp.instantiate(
            i.rmAddress,
            i.mmAddress,
            i.commitDuration,
            i.scoreDriveLogSize,
            i.logDriveLogSize,
            setupHashes[i.level],
            i.level,
            i.epochDuration,
            i.matchDuration,
            i.roundDuration,
            i.finalTime,
            i.machineAddress
        );

    }

    function claimFinished(uint256 _index) public onlyInstantiated(_index) {
        require(instance[_index].currentState == state.DAppRunning, "The state is already Finished");

        bytes32 dAppState = dapp.getCurrentState(instance[_index].dappIndex, msg.sender);

        if (dAppState == "DAppFinished") {
            instance[_index].currentState = state.DAppFinished;
        } else {
            revert("The subinstance compute is still active");
        }
    }

    function isConcerned(uint256, address) public view returns (bool) {
        return true;
    }

    function getState(
        uint256 _index,
        address _user
    ) public view returns (uint256, bytes32) {
        return (
            instance[_index].dappIndex,
            getCurrentState(_index, _user)
        );
    }

    function getCurrentState(uint256 _index, address) public view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.Idle) {
            return "Idle";
        }

        if (instance[_index].currentState == state.DAppRunning) {
            return "DAppRunning";
        }
        if (instance[_index].currentState == state.DAppFinished) {
            return "DAppFinished";
        }

        require(false, "Unrecognized state");
    }

    function getSubInstances(uint256 _index, address)
        public view returns (address[] memory _addresses,
            uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        if (instance[_index].currentState == state.DAppRunning) {
            a = new address[](1);
            i = new uint256[](1);
            a[0] = address(dapp);
            i[0] = instance[_index].dappIndex;
            return (a, i);
        }
        a = new address[](0);
        i = new uint256[](0);
        return (a, i);
    }
}
