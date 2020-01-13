/// @title DAppInterface
/// @author Stephen Chen
pragma solidity ^0.5.0;

import "@cartesi/util/contracts/Instantiator.sol";


contract DAppInterface is Instantiator {

    enum state {
        WaitingCommitAndReveal,
        WaitingMatches,
        DAppFinished
    }


    function instantiate(
        address _rmAddress,
        address _mmAddress,
        uint256 _commitDuration,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        bytes32 _setupHash,
        uint256 _level,

        // MatchManager params
        uint256 _epochDuration,
        uint256 _matchDuration,
        uint256 _roundDuration,
        uint256 _finalTime,
        address _machineAddress ) public returns (uint256);

    function getCurrentState(uint256 _index, address) public view returns (bytes32);

    function getScore(uint256 _index, address _playerAddr) public returns (uint256);
    function getInitialHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function getFinalHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function getLogHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool);
}

