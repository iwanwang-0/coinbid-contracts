// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMining {

    struct MiningInfo {
        uint startTime;
        uint remainingAmout;
        uint remainingTime;
    }

    struct NFTMiningInfo {
        MiningInfo miningInfo;
        uint tokenId;
        address creator;
        string tokenURI;
        bool isInOrder;
    }

    // function ownerOfCanvas(uint _canvaceId) external returns(address);
    function ownerOfNFT(uint _nftId) external returns(address);
    // function transferCanvas(uint _canvasId, address _to) external;
    function transferCreation(uint _creationId, address _to) external;
    function getInfoById(uint _tokenId) external view returns(NFTMiningInfo memory);
}