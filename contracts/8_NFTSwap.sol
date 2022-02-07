// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/ICoinBidCreation.sol";
import "./interface/IMining.sol";
import "./library/UintArray.sol";

contract NFTSwap is Ownable {

    using SafeERC20 for IERC20;
    using UintArray for uint[];

    // Represents an swap on an NFT
    struct Swap {
        uint tokenId;
        address creator;
        // Current owner of NFT
        address seller;
        uint price;
        bool used;
        uint arrIndex;
    }

    struct NFTInfo {
        Swap swap;
        IMining.NFTMiningInfo miningInfo;
    }

    // Map from NFT ID to their corresponding swap.
    mapping (uint256 => Swap) nftIdToSwap;

    uint[] nftInSwapArr;

    // CBD buy back account.
    address cbdBuybackPool;

    ICoinBidCreation internal nft;

    // TODO set value
    IERC20 tokenToPay;

    IMining mining;

    event NFTOrderCreated(uint _tokenId, address _seller, uint _price);
    event NFTOrderCanceled(uint _tokenId, address _seller, uint _price);
    event NFTOrderUpdate(uint _tokenId, uint _price);
    event NFTOrderBought(uint _tokenId, address _seller, uint _price, address _buyer);

    constructor(address _tokenToPay, address _cbdBuybackPool, address _nft, address _mining) {
        tokenToPay = IERC20(_tokenToPay);
        cbdBuybackPool = _cbdBuybackPool;
        nft = ICoinBidCreation(_nft);
        mining = IMining(_mining);
    }

    function getNfTInfo(Swap memory _swap) private view returns(NFTInfo memory) {
        Swap memory swap = _swap;
        IMining.NFTMiningInfo memory miningInfo = mining.getInfoById(swap.tokenId);
        NFTInfo memory info = NFTInfo(_swap, miningInfo);
        return info;
    }

    function getOrders() public view returns(NFTInfo[] memory) {
        NFTInfo[] memory infoArr = new NFTInfo[](nftInSwapArr.length);
        for(uint i = 0; i < nftInSwapArr.length; i++) {
            uint tokenId = nftInSwapArr[i];
            Swap memory swap = nftIdToSwap[tokenId];
            NFTInfo memory info = getNfTInfo(swap);
            infoArr[i] = info;
        }
        return infoArr;
    }

    function getOrderById(uint _tokenId) public view returns(NFTInfo memory) {
        Swap memory swap = nftIdToSwap[_tokenId];
        return getNfTInfo(swap);
    }

    function createOrder(uint _tokenId, uint _price) external {
        address curSender = msg.sender;
        require(mining.ownerOfNFT(_tokenId) == curSender, "NFTSwap: You don't own the nft.");
        address creator = nft.creatorOf(_tokenId);
        Swap memory swap = Swap(_tokenId, creator, curSender, _price, true, nftInSwapArr.length);
        nftIdToSwap[_tokenId] = swap;
        nftInSwapArr.push(_tokenId);
        emit NFTOrderCreated(_tokenId, curSender, _price);
    }

    function cancelOrder(uint _tokenId) external {
        address curSender = msg.sender;
        Swap memory swap = nftIdToSwap[_tokenId];
        require(mining.ownerOfNFT(_tokenId) == curSender, "NFTSwap: You don't own the nft.");
        require(swap.used, "NFTSwap: This token is not in selling.");

        deleteOrder(_tokenId);
        emit NFTOrderCanceled(_tokenId, swap.seller, swap.price);
    }

    function updateOrder(uint _tokenId, uint _price) external {
        address curSender = msg.sender;
        Swap storage swap = nftIdToSwap[_tokenId];
        require(mining.ownerOfNFT(_tokenId) == curSender, "NFTSwap: You don't own the nft.");
        require(swap.used, "NFTSwap: This token is not in selling.");

        swap.price = _price;
        emit NFTOrderUpdate(_tokenId, _price);
    }

    function buy(uint _tokenId) external {
        address curSender = msg.sender;
        Swap memory swap = nftIdToSwap[_tokenId];
        require(mining.ownerOfNFT(_tokenId) != curSender, "NFTSwap: You are already the owner.");
        require(swap.used, "NFTSwap: This token is not in selling.");

        uint amountToSeller = swap.price * 98 / 100;
        uint amountToPool = (swap.price - amountToSeller) / 2; //swap.price * 1 / 100;
        uint amountToCreator = swap.price - amountToSeller - amountToPool; //swap.price * 1 / 100;

        tokenToPay.safeTransferFrom(msg.sender, swap.seller, amountToSeller);
        tokenToPay.safeTransferFrom(msg.sender, cbdBuybackPool, amountToPool);
        tokenToPay.safeTransferFrom(msg.sender, swap.creator, amountToCreator);
        mining.transferCreation(_tokenId, curSender);

        deleteOrder(_tokenId);

        emit NFTOrderBought(_tokenId, swap.seller, swap.price, curSender);
    }

    function deleteOrder(uint _tokenId) private {
        delete nftIdToSwap[_tokenId];
        bool isChanged;
        uint16 index;
        (isChanged, index) = nftInSwapArr.unsafeDelete(index);
        if(isChanged) {
            uint id = nftInSwapArr[index];
            nftIdToSwap[id].arrIndex = index;
        }
    }

    function isInOrder(uint _tokenId) public view returns(bool) {
        return nftIdToSwap[_tokenId].used;
    }

    function setTokenToPay(address _token) public onlyOwner {
        tokenToPay = IERC20(_token);
    }

    function setCbdBuybackPool(address _cbdBuybackPool) public onlyOwner {
        cbdBuybackPool = _cbdBuybackPool;
    }

    function setNft(address _nft) public onlyOwner {
        nft = ICoinBidCreation(_nft);
    }

    function setMining(address _mining) public onlyOwner {
        mining = IMining(_mining);
    }
}