/// @title RevealInterface
/// @author Felipe Argento
pragma solidity ^0.5.0;

import "./Instantiator.sol";


contract RevealInterface is Instantiator {

    enum state {
        CommitPhase,
        RevealPhase,
        PhaseFinished
    }

    function instantiate(
        uint256 _commitDuration,
        uint256 _revealDuration,
        bytes32 _initialHash) public returns (uint256);

    function getScore(uint256 _index, address _playerAddr) public returns (uint256);
    function getInitialHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function getFinalHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool);
    function playerExist(uint256 _index, address _playerAddr) public returns (bool);
    function getCurrentState(uint256 _index, address concernedAddress) public view returns (bytes32);

}
