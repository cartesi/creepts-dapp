/// @title RevealInterface
/// @author Felipe Argento
pragma solidity ^0.5.0;

import "./Instantiator.sol";

contract RevealInterface is Instantiator {

    enum state {
        CommitPhase,
        RevealPhase,
        CommitRevealDone
    }

    function instantiate(
        uint256 _commitDuration,
        uint256 _revealDuration,
        uint256 _scoreWordPosition,
        uint256 _logDrivePosition,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        bytes32 _templateHash) public returns (uint256);

    function getScore(uint256 _index, address _playerAddr) public returns (uint256);

    function getLogHash(uint256 _index, address _playerAddr) public returns (bytes32);


    function getInitialHash(uint256 _index, address _playerAddr) public returns (bytes32);

    function getFinalHash(uint256 _index, address _playerAddr) public returns (bytes32);

    function playerExist(uint256 _index, address _playerAddr) public returns (bool);

    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool);

    function isConcerned(uint256 _index, address _user) public view returns (bool);

    function getCurrentState(uint256 _index) public view returns (bytes32);

    function getState(uint256 _index, address _user)
    public view returns (
        uint256[6] memory _uintValues,
        bytes32 logHash,

        bool revealed,
        bool logAvailable,

        bytes32 currentState
    );
}
