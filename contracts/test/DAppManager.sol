/// @title DAppManager
/// @author Felipe Argento
pragma solidity ^0.5.0;


import "@cartesi/util/contracts/Decorated.sol";
import "../DAppInterface.sol";

contract DAppManager is Decorated, Instantiator {

    DAppInterface private dapp;

    enum state {
        Idle,
        DAppRunning,
        DAppFinished
    }

    struct DAppManagerCtx {
        uint256 dappIndex;
        address dappAddress;

        // RevealCommit vars
        address rmAddress;
        address mmAddress;
        uint256 commitDuration;
        uint256 revealDuration;
        uint256 scoreWordPosition;
        uint256 logDrivePosition;
        uint256 scoreDriveLogSize;
        uint256 logDriveLogSize;
        bytes32 setupHash;
        bytes32 tournamentName;
        uint256 level;

        // matchmanager
        uint256 epochDuration;
        uint256 matchDuration;
        uint256 roundDuration;
        uint256 finalTime;
        address machineAddress;

        state currentState;
    }

    mapping(uint256 => DAppManagerCtx) internal instance;

    constructor(
        address _dappAddress,
        address _rmAddress,
        address _mmAddress,
        uint256 _commitDuration,
        uint256 _revealDuration,
        uint256 _scoreWordPosition,
        uint256 _logDrivePosition,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        bytes32 _setupHash,
        bytes32 _tournamentName,
        uint256 _level,

        uint256 _epochDuration,
        uint256 _matchDuration,
        uint256 _roundDuration,
        uint256 _finalTime,
        address _machineAddress
    ) public {
        dapp = DAppInterface(_dappAddress);

        currentIndex = 0;

        instance[currentIndex].rmAddress = _rmAddress;
        instance[currentIndex].mmAddress = _mmAddress;
        instance[currentIndex].commitDuration = _commitDuration;
        instance[currentIndex].revealDuration = _revealDuration;
        instance[currentIndex].scoreWordPosition = _scoreWordPosition;
        instance[currentIndex].logDrivePosition = _logDrivePosition;
        instance[currentIndex].scoreDriveLogSize = _scoreDriveLogSize;
        instance[currentIndex].logDriveLogSize = _logDriveLogSize;
        instance[currentIndex].setupHash = _setupHash;
        instance[currentIndex].tournamentName = _tournamentName;
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
        DAppManagerCtx memory i = instance[_index];
        require(i.currentState == state.Idle, "State has to be Idle");

        instance[_index].currentState = state.DAppRunning;

        instance[_index].dappIndex = dapp.instantiate(
            i.rmAddress,
            i.mmAddress,
            i.commitDuration,
            i.revealDuration,
            i.scoreWordPosition,
            i.logDrivePosition,
            i.scoreDriveLogSize,
            i.logDriveLogSize,
            i.setupHash,
            "mock tournament",
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
            instance[currentIndex].currentState = state.DAppFinished;
        } else {
            revert("The subinstance compute is still active");
        }
    }

    function isConcerned(uint256 _index, address _user) public view returns (bool) {
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
