/// @title Dapp
/// @author Stephen Chen
pragma solidity ^0.5.0;

import "./RevealInterface.sol";
import "./MatchManagerInterface.sol";
import "./Decorated.sol";
import "./Instantiator.sol";


contract DApp is Decorated, Instantiator {
    address public owner;

    enum state {
        WaitingCommitAndReveal,
        WaitingMatches,
        DAppFinished
    }

    struct DAppCtx {
        RevealInterface rm;
        MatchManagerInterface mm;
        uint256 revealIndex;
        uint256 matchManagerIndex;
        address machineAddress;
        bytes32 initialHash; // initial hash of cartesi machine of the tournament
        bytes32 tournamentName; // name of the tournament

        state currentState;
    }

    mapping(uint256 => DAppCtx) internal instance;


    constructor() public {
        owner = msg.sender;
    }

    function instantiate(
        address _rmAddress,
        address _mmAddress,
        address _machineAddress,
        bytes32 _initialHash,
        bytes32 _tournamentName) public
        onlyBy(owner)
    {

        instance[currentIndex].rm = RevealInterface(_rmAddress);
        instance[currentIndex].mm = MatchManagerInterface(_mmAddress);

        instance[currentIndex].machineAddress = _machineAddress;
        instance[currentIndex].initialHash = _initialHash;
        instance[currentIndex].tournamentName = _tournamentName;

        instance[currentIndex].currentState = state.WaitingCommitAndReveal;
        instance[currentIndex].revealIndex = instance[currentIndex].rm.instantiate(
            200, //commit duration
            200, //reveal duration
            _initialHash //inital hash
        );

        active[currentIndex] = true;
        currentIndex++;

        return;
    }

    function claimMatches(uint256 _index) public
        onlyBy(owner)
        onlyInstantiated(_index)
    {
        require(instance[_index].currentState == state.WaitingCommitAndReveal, "The state is not WaitingCommitAndReveal");

        bytes32 revealState = instance[currentIndex].rm.getCurrentState(instance[_index].revealIndex, msg.sender);

        if (revealState == "PhaseFinished") {

            instance[_index].currentState = state.WaitingMatches;
            instance[_index].matchManagerIndex = instance[_index].mm.instantiate(
                100, //epoch duration
                50, //match duration
                25, //round duration
                13000, //final time
                address(this), // dapp address
                _index, // dapp index
                instance[_index].machineAddress);
        } else {
            revert("The subinstance commit and reveal is still active");
        }
    }

    function claimFinished(uint256 _index) public
        onlyBy(owner)
        onlyInstantiated(_index)
    {
        require(instance[_index].currentState == state.WaitingMatches, "The state is not WaitingMatches");

        bytes32 matchManagerState = instance[currentIndex].mm.getCurrentState(instance[_index].matchManagerIndex, msg.sender);

        if (matchManagerState == "MatchesOver") {
            instance[currentIndex].currentState = state.DAppFinished;
        } else {
            revert("The subinstance matches is still active");
        }
    }

    function isConcerned(uint256 _index, address) public view
        onlyInstantiated(_index)
        returns (bool)
    {
        // everyone could participate in the game
        return true;
    }

    function getState(uint256 _index, address _user) public view
        onlyInstantiated(_index)
        returns (bytes32, bytes32, bytes32)
    {
        return (instance[_index].tournamentName, instance[_index].initialHash, getCurrentState(_index, _user));
    }

    function getCurrentState(uint256 _index, address) public view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.WaitingCommitAndReveal) {
            return "WaitingCommitAndReveal";
        }
        if (instance[_index].currentState == state.WaitingMatches) {
            return "WaitingMatches";
        }
        if (instance[_index].currentState == state.DAppFinished) {
            return "DAppFinished";
        }

        require(false, "Unrecognized state");
    }

    function getSubInstances(uint256 _index, address) public view
        onlyInstantiated(_index)
        returns (address[] memory _addresses, uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        if (instance[_index].currentState == state.WaitingCommitAndReveal) {
            a = new address[](1);
            i = new uint256[](1);
            a[0] = address(instance[currentIndex].rm);
            i[0] = instance[_index].revealIndex;
        } else if (instance[_index].currentState == state.WaitingMatches ||
            instance[_index].currentState == state.DAppFinished) {
            a = new address[](2);
            i = new uint256[](2);
            a[0] = address(instance[currentIndex].rm);
            i[0] = instance[_index].revealIndex;
            a[1] = address(instance[currentIndex].mm);
            i[1] = instance[_index].matchManagerIndex;
        } else {
            a = new address[](0);
            i = new uint256[](0);
        }
        return (a, i);
    }

    function getScore(uint256 _index, address _playerAddr) public returns (uint256) {
        return instance[_index].rm.getScore(_index, _playerAddr);
    }

    function getInitialHash(uint256 _index, address _playerAddr) public returns (bytes32) {
        return instance[_index].rm.getInitialHash(_index, _playerAddr);
    }

    function getFinalHash(uint256 _index, address _playerAddr) public returns (bytes32) {
        return instance[_index].rm.getFinalHash(_index, _playerAddr);
    }

    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool) {
        return instance[_index].rm.hasRevealed(_index, _playerAddr);
    }
}

