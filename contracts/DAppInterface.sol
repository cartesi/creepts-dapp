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
        uint256 _revealDuration,
        uint256 _scoreDriveLogSize,
        uint256 _logDriveLogSize,
        bytes32 _setupHash,
        uint256 _level,

        // MatchManager params
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

