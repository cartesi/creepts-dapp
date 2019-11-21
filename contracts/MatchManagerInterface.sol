/// @title MatchManagerInterface
/// @author Felipe Argento
pragma solidity ^0.5.0;

import "@cartesi/util/contracts/Instantiator.sol";


contract MatchManagerInterface is Instantiator {

    enum state {
        WaitingMatches,
        MatchesOver
    }

    function instantiate(
        uint256 _epochDuration,
        uint256 _matchDuration,
        uint256 _roundDuration,
        uint256 _finalTime,
        address _dappAddress,
        uint256 _dappInstance,
        address _machineAddress) public returns (uint256);

    function advanceEpoch(uint256 _index) public;

    function playNextEpoch(uint256 _index) public;

    function claimWin(uint256 _index) public returns (address);

    function isConcerned(uint256 _index, address _user) public view returns (bool);

    // TO-DO: Add registration duration - Also update offchain
    // add corresposding state
    function getState(uint256 _index, address) public view returns
        ( uint256[9] memory _uintValues,
          address[3] memory _addressValues,
          bytes32 initialHash,
          bool registered,
          bytes32 currentState
        );

    function getCurrentState(uint256 _index, address) public view returns (bytes32);

}

