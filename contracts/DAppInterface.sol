/// @title DAppInterface
/// @author Stephen Chen
pragma solidity ^0.5.0;

import "./Instantiator.sol";


contract DAppInterface is Instantiator {

    function getScore(uint256 _index, address _playerAddr) public returns (uint256);
    function getInitialHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function getFinalHash(uint256 _index, address _playerAddr) public returns (bytes32);
    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool);
}

