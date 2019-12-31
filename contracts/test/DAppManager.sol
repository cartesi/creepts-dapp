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

    mapping(uint256 => DAppManagerCtx) internal instance;
    bytes32[8] setupHashes = [
        bytes32(0x83a2b88934ac816c45e810b1c4344b214f88ccc7ecc9b5917cf6051b789974dd),
        bytes32(0xdb886e23cce224acb75ae42bdebe44bbf07a3eca51a6629043d1e4e6518a42cb),
        bytes32(0x425b43d06f55cce660a04bd4b605536f13fb6dab5072f5ce62f3527e02db8718),
        bytes32(0xa236a1fc9b5c31ef0d02801c1f00cc84e1d8afd0433797e201b5044676a39108),
        bytes32(0xa7700ff2f7e37ef8ade81d66926373688960812568485e4deecf02598b57e2b9),
        bytes32(0x367d8064182ac7e32c33604cf1c77bbabea8c1810f9d3007414d1bdcfda11196),
        bytes32(0xcd6bdaba99ef44c205ffa08f5c78d043d40a45ecd0ee54f94fb8865a3d6ddd37),
        bytes32(0xbc221d51b0d9c024e0d2bb9067ad42907b17da6e916d20eab2d538561044db46)
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
        DAppManagerCtx memory i = instance[_index];
        require(i.currentState == state.Idle, "State has to be Idle");

        instance[_index].currentState = state.DAppRunning;

        // !!! setupHash should be modified manually in the DAppManager contract !!!
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
