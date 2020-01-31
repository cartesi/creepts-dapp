// Copyright (C) 2020 Cartesi Pte. Ltd.

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

/// @title DApp
/// @author Stephen Chen
pragma solidity ^0.5.0;

import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/tournament/contracts/RevealInterface.sol";
import "@cartesi/tournament/contracts/MatchManagerInterface.sol";
import "./DAppInterface.sol";


contract DApp is Decorated, DAppInterface {
    address public owner;

    struct DAppCtx {
        RevealInterface rm;
        MatchManagerInterface mm;
        uint256 revealIndex;
        uint256 matchManagerIndex;
        bytes32 setupHash; // initial hash of cartesi machine of the tournament
        uint256 level; // map level

        // MatchManager params
        uint256 matchDuration;
        uint256 roundDuration;
        uint256 finalTime;
        address parentAddress;
        uint256 parentInstance;
        address machineAddress;
        state currentState;
    }

    mapping(uint256 => DAppCtx) internal instance;


    constructor() public {
        owner = msg.sender;
    }

    // add check onlyOwner(msg.sender)
    function instantiate(
        address _rmAddress,
        address _mmAddress,
        uint256 _commitDuration,
        uint256 _revealDuration,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        bytes32 _setupHash,
        uint256 _level,

        // MatchManager params
        uint256 _matchDuration,
        uint256 _roundDuration,
        uint256 _finalTime,
        address _machineAddress) public returns (uint256)
    {

        instance[currentIndex].rm = RevealInterface(_rmAddress);
        instance[currentIndex].mm = MatchManagerInterface(_mmAddress);

        instance[currentIndex].setupHash = _setupHash;
        instance[currentIndex].level = _level;

        instance[currentIndex].matchDuration = _matchDuration;
        instance[currentIndex].roundDuration = _roundDuration;
        instance[currentIndex].finalTime = _finalTime;

        instance[currentIndex].machineAddress = _machineAddress;


        instance[currentIndex].currentState = state.WaitingCommitAndReveal;
        instance[currentIndex].revealIndex = instance[currentIndex].rm.instantiate(
            _commitDuration,
            _revealDuration,
            (1<<63)+(3<<61), //scoreWordPosition,
            (1<<63)+(2<<61), //logDrivePosition,
            _scoreDriveLogSize,
            _logDriveLogSize,
            _setupHash
        );

        active[currentIndex] = true;
        return currentIndex++;
    }

    function claimMatches(uint256 _index) public onlyInstantiated(_index) {
        require(instance[_index].currentState == state.WaitingCommitAndReveal, "The state is not WaitingCommitAndReveal");

        bytes32 revealState = instance[_index].rm.getCurrentState(instance[_index].revealIndex);

        if (revealState == "CommitRevealDone") {

            instance[_index].currentState = state.WaitingMatches;
            instance[_index].matchManagerIndex = instance[_index].mm.instantiate(
                instance[_index].matchDuration,
                instance[_index].roundDuration,
                instance[_index].finalTime,
                address(this), // dapp address
                _index, // dapp index
                instance[_index].machineAddress);
        } else {
            revert("The subinstance commit and reveal is still active");
        }
    }

    function claimFinished(uint256 _index) public
        onlyInstantiated(_index)
    {
        require(instance[_index].currentState == state.WaitingMatches, "The state is not WaitingMatches");

        bytes32 matchManagerState = instance[_index].mm.getCurrentState(instance[_index].matchManagerIndex);

        if (matchManagerState == "MatchesOver") {
            instance[_index].currentState = state.DAppFinished;
            deactivate(_index);
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
        returns (
            uint256,
            bytes32,
            uint256,
            bytes32
        )
    {
        return (
            instance[_index].level,
            instance[_index].setupHash,
            instance[_index].finalTime,
            getCurrentState(_index, _user));
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
            a[0] = address(instance[_index].rm);
            i[0] = instance[_index].revealIndex;
        } else if (instance[_index].currentState == state.WaitingMatches ||
            instance[_index].currentState == state.DAppFinished) {
            a = new address[](2);
            i = new uint256[](2);
            a[0] = address(instance[_index].rm);
            i[0] = instance[_index].revealIndex;
            a[1] = address(instance[_index].mm);
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

    function getLogHash(uint256 _index, address _playerAddr) public returns (bytes32) {
        return instance[_index].rm.getLogHash(_index, _playerAddr);
    }

    function hasRevealed(uint256 _index, address _playerAddr) public returns (bool) {
        return instance[_index].rm.hasRevealed(_index, _playerAddr);
    }
}

