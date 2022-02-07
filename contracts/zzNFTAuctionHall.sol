// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IMining.sol";

contract NFTAuctionHall is Ownable {

    using SafeERC20 for IERC20;

    IMining mining;

    uint64 nftAuctionDuration;

    // TODO set value
    IERC20 cbd;
    uint8 cbdDecimals = 18;

    // Trust fund pool
    address pool;

    // Represents an auction on an NFT
    struct NFTAuction {
        // Current owner of NFT
        address seller;
        uint128 lastPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint startedAt;
        address lastBidder;
        bool used;
    }

    // Map from NFT ID to their corresponding auction.
    mapping (uint256 => NFTAuction) nftIdToAuction;

    event NFTAuctionCreated(uint nftId, uint256 startingPrice, uint256 duration);
    event NFTAuctionBid(uint nftId, uint256 bidPrice, address bidder);
    event NFTAuctionEnded(uint nftId, uint price, address buyer);

    constructor(address _mining, address _cbd, address _pool) {
        mining = IMining(_mining);
        cbd = IERC20(_cbd);
        pool = _pool;
        nftAuctionDuration = 1 days;
    }

    function createNFTAuction(uint _nftId, uint128 _price) public {
        require(msg.sender == mining.ownerOfNFT(_nftId), "NFTAuctionHall: Your're not the owner");
        require(!nftIdToAuction[_nftId].used, "NFTAuctionHall: Already list for auction");

        NFTAuction memory nftAuction = NFTAuction(msg.sender, _price, nftAuctionDuration, 
            block.timestamp, msg.sender, true);
        nftIdToAuction[_nftId] = nftAuction;

        emit NFTAuctionCreated(_nftId, _price, nftAuctionDuration);
    }

    function bidNFT(uint _nftId, uint128 _price) public {
        require(msg.sender != mining.ownerOfNFT(_nftId), "NFTAuctionHall: Your're already the owner");
        require(nftIdToAuction[_nftId].used, "NFTAuctionHall: Haven't listed for auction yet");
        NFTAuction storage auction = nftIdToAuction[_nftId];

        require(_price > auction.lastPrice, "NFTAuctionHall: price too low");
        require(block.timestamp <= auction.startedAt + nftAuctionDuration, "NFTAuctionHall: already ended");

        cbd.safeTransferFrom(address(this), auction.lastBidder, auction.lastPrice);
        cbd.safeTransferFrom(msg.sender, address(this), _price);

        auction.lastPrice = _price;
        auction.lastBidder = msg.sender;
        
        emit NFTAuctionBid(_nftId, _price, msg.sender);
    }

    function canvasAuctionEnd(uint _nftId) public {
        NFTAuction memory auction = nftIdToAuction[_nftId];

        require(auction.used, "NFTAuctionHall: Auction uncreated");
        require(block.timestamp > (auction.startedAt + auction.duration), "NFTAuctionHall: Auction is not over yet");
        require(msg.sender == auction.lastBidder, "NFTAuctionHall: You're not the highest bidder");

        delete nftIdToAuction[_nftId];
        
        cbd.safeTransferFrom(address(this), pool, auction.lastPrice);
        mining.transferCreation(_nftId, msg.sender);
        emit NFTAuctionEnded(_nftId, auction.lastPrice, msg.sender);
    }

    function setMining(address _mining) external onlyOwner {
        mining = IMining(_mining);
    }

    function setCBD(address _cbd) external {
        cbd = IERC20(_cbd);
    }

    function setPool(address _pool) external {
        pool = _pool;
    }
}