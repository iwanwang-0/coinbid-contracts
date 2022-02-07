// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interface/IMining.sol";
import "./Governance.sol";
import "./library/UintArray.sol";
import "./interface/IPeriod.sol";
import "./interface/ICoinBidCreation.sol";
import "./interface/INFTSwap.sol";

contract Mining is IMining, Governance {

    using SafeERC20 for IERC20;
    using UintArray for uint[];
    using Math for uint;

    struct Ownership {
        address owner;
        uint16 arrIndex;
    }

    // struct MiningInfo {
    //     uint startTime;
    //     uint remainingAmout;
    //     uint remainingTime;
    // }

    // struct NFTMiningInfo {
    //     MiningInfo miningInfo;
    //     uint tokenId;
    //     string tokenURI;
    //     bool isInOrder;
    // }

    // mapping(address => uint[]) internal myOwnedCanvas;
    // mapping(uint => Ownership) internal canvasOwnership;

    mapping(address => uint[]) internal myOwnedCreations;
    mapping(uint => Ownership) internal creationOwnership;

    mapping(uint => MiningInfo) miningInfoMap;
    uint defaultAmount;
    uint defaultLong;// 每个NFT挖矿总时长

    // TODO set value
    IERC20 cbd;
    uint8 cbdDecimals = 18;

    IPeriod periodMana;

    ICoinBidCreation internal nft;

    INFTSwap internal swap;

    event CanvasTransferred(uint canvasId, address from, address to);
    event CreationTransferred(uint creationId, address from, address to);

    constructor(address _cbd, address _periodMana, address _nft) {
        cbd = IERC20(_cbd);
        periodMana = IPeriod(_periodMana);
        nft = ICoinBidCreation(_nft);
        defaultAmount = 1000 * (10 ** cbdDecimals);
        defaultLong = 1000 * periodMana.getPeriod();
    }

    // function transferCanvas(uint _canvasId, address _to) override public onlyGovernance {
    //     require(_to != address(0), "Mining: can not transfer to zero address");
        
    //     Ownership memory oldOwnership = canvasOwnership[_canvasId];
    //     myOwnedCanvas[_to].push(_canvasId);
    //     if(oldOwnership.owner != address(0x0)) {
    //         Ownership storage newOwnership = canvasOwnership[_canvasId];
    //         newOwnership.owner = _to;
    //         newOwnership.arrIndex = uint16(myOwnedCanvas[_to].length - 1);
    //         bool isChanged;
    //         uint16 index;
    //         (isChanged, index) = myOwnedCanvas[oldOwnership.owner].unsafeDelete(oldOwnership.arrIndex);
    //         if(isChanged) {
    //             uint canvasId = myOwnedCanvas[oldOwnership.owner][index];
    //             canvasOwnership[canvasId].arrIndex = index;
    //         }
    //     } else {
    //         Ownership memory ownership = Ownership(_to, uint16(myOwnedCanvas[_to].length - 1));
    //         canvasOwnership[_canvasId] = ownership;
    //     }
        
    //     emit CanvasTransferred(_canvasId, oldOwnership.owner, _to);
    // }

    function transferCreation(uint _creationId, address _to) override public onlyGovernance {
        require(_to != address(0), "Mining: can not transfer to zero address");

        Ownership memory oldOwnership = creationOwnership[_creationId];
        myOwnedCreations[_to].push(_creationId);
        if(oldOwnership.owner != address(0x0)) {
            Ownership storage newOwnership = creationOwnership[_creationId];
            newOwnership.owner = _to;
            newOwnership.arrIndex = uint16(myOwnedCreations[_to].length - 1);
            bool isChanged;
            uint16 index;
            (isChanged, index) = myOwnedCreations[oldOwnership.owner].unsafeDelete(oldOwnership.arrIndex);
            if(isChanged) {
                uint creationId = myOwnedCreations[oldOwnership.owner][index];
                creationOwnership[creationId].arrIndex = index;
            }

            MiningInfo storage info = miningInfoMap[_creationId];
            uint mined = 0;
            if(block.timestamp > info.startTime) {
                uint lastTime = Math.min(block.timestamp, info.startTime + info.remainingTime);
                uint dist = lastTime - info.startTime;
                mined = info.remainingAmout / info.remainingTime * dist;
                cbd.safeTransfer(oldOwnership.owner, mined);
                info.startTime = lastTime;
                info.remainingAmout = info.remainingAmout - mined;
                info.remainingTime = info.remainingTime - dist;
            }
        } else {
            Ownership memory ownership = Ownership(_to, uint16(myOwnedCreations[_to].length - 1));
            creationOwnership[_creationId] = ownership;

            MiningInfo memory info = MiningInfo(block.timestamp, defaultAmount, defaultLong);
            miningInfoMap[_creationId] = info;
        }

        emit CreationTransferred(_creationId, oldOwnership.owner, _to);
    }

    function earned(address _theOwner) public view returns(uint) {
        uint[] memory tokenIdArr = myOwnedCreations[_theOwner];
        uint total = 0;
        for(uint i = 0; i < tokenIdArr.length; i++) {
            uint tokenID = tokenIdArr[i];
            MiningInfo memory info = miningInfoMap[tokenID];
            uint mined = 0;
            if(block.timestamp > info.startTime) {
                uint lastTime = Math.min(block.timestamp, info.startTime + info.remainingTime);
                uint dist = lastTime - info.startTime;
                mined = info.remainingAmout / info.remainingTime * dist;
                total = total + mined;
            }
        }
        return total;
    }

    function dailyEarning(address _theOwner) public view returns(uint) {
        uint[] memory tokenIdArr = myOwnedCreations[_theOwner];
        uint total = 0;
        for(uint i = 0; i < tokenIdArr.length; i++) {
            uint tokenID = tokenIdArr[i];
            MiningInfo memory info = miningInfoMap[tokenID];
            if(block.timestamp > info.startTime && (block.timestamp < (info.startTime + info.remainingTime))) {
                total += 1;
            }
        }
        return total;
    }

    function claim() public {
        uint[] memory tokenIdArr = myOwnedCreations[msg.sender];
        uint total = 0;
        for(uint i = 0; i < tokenIdArr.length; i++) {
            uint tokenID = tokenIdArr[i];
            MiningInfo memory info = miningInfoMap[tokenID];
            if(block.timestamp > info.startTime) {
                uint lastTime = Math.min(block.timestamp, info.startTime + info.remainingTime);
                uint dist = lastTime - info.startTime;
                uint mined = info.remainingAmout / info.remainingTime * dist;
                total = total + mined;

                info = MiningInfo(lastTime, info.remainingAmout - mined, info.remainingTime - dist);
                delete miningInfoMap[tokenID];
                miningInfoMap[tokenID] = info;
            }
        }
        cbd.safeTransfer(msg.sender, total);
    }

    // 如果NFT太多，用以上 claim() 函数可能会超出Gas Limit
    function claim(uint _from, uint _to) public {
        uint[] memory tokenIdArr = myOwnedCreations[msg.sender];
        uint total = 0;
        require(_from >= tokenIdArr.length, "Mining: index out of range");
        uint to = (_to < tokenIdArr.length) ? _to : tokenIdArr.length;

        for(uint i = _from; i < to; i++) {
            uint tokenID = tokenIdArr[i];
            MiningInfo memory info = miningInfoMap[tokenID];
            if(block.timestamp > info.startTime) {
                uint lastTime = Math.min(block.timestamp, info.startTime + info.remainingTime);
                uint dist = lastTime - info.startTime;
                uint mined = info.remainingAmout / info.remainingTime * dist;
                total = total + mined;
                
                info = MiningInfo(lastTime, info.remainingAmout - mined, info.remainingTime - dist);
                delete miningInfoMap[tokenID];
                miningInfoMap[tokenID] = info;
            }
        }
        cbd.safeTransfer(msg.sender, total);
    }

    function getMyOwnedCreations(address _theOwner) public view returns(NFTMiningInfo[] memory) {
        uint[] memory myOwnedArr = myOwnedCreations[_theOwner];
        NFTMiningInfo[] memory infoArr = new NFTMiningInfo[](myOwnedArr.length);
        for(uint i = 0; i < myOwnedArr.length; i++) {
            uint tokenId = myOwnedArr[i];
            MiningInfo memory miningInfo = miningInfoMap[tokenId];
            NFTMiningInfo memory info = getNfTInfo(miningInfo, tokenId);
            infoArr[i] = info;
        }
        return infoArr;
    }

    function getNfTInfo(MiningInfo memory _miningInfo, uint _tokenId) private view returns(NFTMiningInfo memory) {
        NFTMiningInfo memory info = NFTMiningInfo(_miningInfo, _tokenId, address(0), "", false);
        if(_tokenId != 0) {
            info.tokenURI = nft.tokenURI(_tokenId);
            info.isInOrder = swap.isInOrder(_tokenId);
            info.creator = nft.creatorOf(_tokenId);
        }
        return info;
    }

    function getInfoById(uint _tokenId) public override view returns(NFTMiningInfo memory) {
        MiningInfo memory miningInfo = miningInfoMap[_tokenId];
        return getNfTInfo(miningInfo, _tokenId);
    }

    // function ownerOfCanvas(uint _canvaceId) override external view returns(address) {
    //     return canvasOwnership[_canvaceId].owner;
    // }

    function ownerOfNFT(uint _nftId) override external view returns(address) {
        return creationOwnership[_nftId].owner;
    }

    function setCbd(address _cbd) public onlyOwner {
        cbd = IERC20(_cbd);
    }

    function setNft(address _nft) public onlyOwner {
        nft = ICoinBidCreation(_nft);
    }

    function setSwap(address _swap) public onlyOwner {
        swap = INFTSwap(_swap);
    }
}