// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/UintArray.sol";
import "./interface/IPeriod.sol";
import "./interface/ICoinBidCreation.sol";
import "./interface/ICanvasAuction.sol";
import "./interface/IMining.sol";

contract NFTAuction is Ownable, IERC721Receiver {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using UintArray for uint[];

    // auto increament.
    Counters.Counter private _tokenIdCounter;

    // Represents an auction on an NFT
    struct Auction {
        uint tokenId;
        address creator;
        // Current owner of NFT
        address seller;
        uint128 lastPrice;
        // Time when auction ended
        uint endAt;
        // Time when auction started
        uint startedAt;
        address lastBidder;
        bool used;
        uint arrIndex;
    }

    struct NFTInfo {
        Auction auction;
        string tokenURI;
    }

    // Map from NFT ID to their corresponding auction.
    mapping (uint256 => Auction) nftIdToAuction;

    uint totalAmount;
    uint[] nftInAuctionArr;

    IPeriod nftFactory;

    // 周期长度
    uint public period;

    // 默认价格
    uint128 internal defaultPrice;

    // The platform creator.
    address platformCreator;
    // CBD buy back account.
    address cbdBuybackPool;
    // strategic reserve fund pool.
    address reserveFundPool;
    // Platform operating pool.
    address platformPool;

    ICoinBidCreation internal nft;
    ICanvasAuction internal canvasAuction;

    // TODO set value
    IERC20 tokenToPay;

    IMining mining;

    event NFTAuctionCreated(uint nftId, uint256 startingPrice, uint256 duration);
    event NFTAuctionBid(uint nftId, uint256 bidPrice, address bidder);
    event NFTAuctionEnded(uint nftId, uint price, address buyer);

    constructor(address _nftFactory, 
                address _tokenToPay, 
                address _platformCreator, 
                address _cbdBuybackPool,
                address _reserveFundPool,
                address _platformPool,
                address _nft, 
                address _mining, 
                address _canvasAuction, 
                uint128 _defaultPrice) {
        nftFactory = IPeriod(_nftFactory);
        period = nftFactory.getPeriod();
        tokenToPay = IERC20(_tokenToPay);

        platformCreator = _platformCreator;
        cbdBuybackPool = _cbdBuybackPool;
        reserveFundPool = _reserveFundPool;
        platformPool = _platformPool;

        nft = ICoinBidCreation(_nft);
        mining = IMining(_mining);
        canvasAuction = ICanvasAuction(_canvasAuction);
        defaultPrice = _defaultPrice;
    }

    function getNFTInAuction(uint8 _amountPerPage, uint32 _page) public view returns(NFTInfo[] memory, uint) {
        NFTInfo[] memory arr = new NFTInfo[](_amountPerPage);
        uint startPoint = _amountPerPage * _page;
        // uninstanted amount.
        uint rawAmount = getUninstantedAmount();
        uint totalLength = nftInAuctionArr.length + rawAmount;
        if((totalLength > 0) && ((totalLength - 1) >= startPoint)) {
            for(uint i = 0; i < _amountPerPage; i++) {
                if((totalLength - 1) < (startPoint + i)) {
                    break;
                }

                Auction memory auction;
                bool a = nftInAuctionArr.length > 0;
                bool b = false;
                if(a) {
                    b = (nftInAuctionArr.length - 1) >= (startPoint + i);
                }
                if(a && b) {
                    uint index = nftInAuctionArr[startPoint + i];
                    auction = nftIdToAuction[index];
                    // no bid yet.
                    if(auction.lastBidder == address(0)) {
                        auction = getNoBidAuction(auction);
                    }
                } else {
                    // 已实例化的不够了，可以用未实例化的填充。
                    auction = Auction(0, platformCreator, platformCreator, 0, 0, 0, platformCreator, false, 0);
                    auction = getNoBidAuction(auction);
                }
                arr[i] = getNfTInfo(auction);
            }
        }
        return (arr, totalLength);
    }

    function getAuctionById(uint _tokenId) public view returns(NFTInfo memory) {
        Auction memory auction = nftIdToAuction[_tokenId];
        // no bid yet.
        if(auction.lastBidder == address(0)) {
            auction = getNoBidAuction(auction);
        }

        return getNfTInfo(auction);
    }

    function getNoBidAuction(Auction memory _auction) private view returns(Auction memory) {
        Auction memory auction = _auction;
        auction.startedAt = nftFactory.getCurPeriodStartAt();
        auction.endAt = auction.startedAt + period;
        auction.lastPrice = defaultPrice;
        auction.seller = auction.creator;
        auction.lastBidder = auction.creator;
        return auction;
    }

    function getNfTInfo(Auction memory _auction) private view returns(NFTInfo memory) {
        NFTInfo memory info = NFTInfo(_auction, "");
        if(_auction.tokenId != 0) {
            info.tokenURI = nft.tokenURI(_auction.tokenId);
        }
        return info;
    }

    function getUninstantedAmount() internal view returns(uint) {
        uint total = nftFactory.getTotalAmount();
        if(totalAmount >= total) {
            return 0;
        }
        return total - totalAmount;
    }

    function bidUninstanted(string memory _tokenURI, uint128 _price) public {
        uint amount = getUninstantedAmount();
        require(amount > 0, "NFTAuction: Invalid NFT");
        require(_price > defaultPrice, "NFTAuction: price too low");

        tokenToPay.safeTransferFrom(msg.sender, address(this), _price);

        uint tokenId = createNFT(_tokenURI, platformCreator);

        uint startedAt = nftFactory.getCurPeriodStartAt();
        uint endAt = startedAt + period;
        Auction memory auction = Auction(tokenId, platformCreator, platformCreator, _price, endAt, startedAt, msg.sender, true, nftInAuctionArr.length);
        nftIdToAuction[tokenId] = auction;
        nftInAuctionArr.push(tokenId);
        totalAmount += 1;

        emit NFTAuctionCreated(tokenId, defaultPrice, period);
        emit NFTAuctionBid(tokenId, _price, msg.sender);
    }

    // 通过画布创建NFT，创建后创建者是用户
    function createNFTByCanvas(string memory _tokenURI) public {
        require(canvasAuction.popOne(msg.sender), "NFTAuction: There isn't any canvas in your wallet");
        uint tokenId = createNFT(_tokenURI, msg.sender);

        uint startedAt = nftFactory.getCurPeriodStartAt();
        uint endAt = startedAt + period;
        Auction memory auction = Auction(tokenId, msg.sender, msg.sender, defaultPrice, endAt, startedAt, address(0), true, nftInAuctionArr.length);
        nftIdToAuction[tokenId] = auction;
        nftInAuctionArr.push(tokenId);
        totalAmount += 1;

        emit NFTAuctionCreated(tokenId, defaultPrice, period);
    }

    // 假的NFT实例化，创建后创建者是归平台
    function createNFT(string memory _tokenURI, address _creator) private returns(uint) {
        // start at 1
        _tokenIdCounter.increment();
        uint id = _tokenIdCounter.current();
        nft.safeMint(address(this), id, _tokenURI, _creator);
        return id;
    }

    function bid(uint _tokenId, uint128 _price) external {
        require(msg.sender != mining.ownerOfNFT(_tokenId), "NFTAuction: Your're already the owner");
        require(nftIdToAuction[_tokenId].used, "NFTAuction: Haven't listed for auction yet");
        Auction storage auction = nftIdToAuction[_tokenId];
        require(_price > auction.lastPrice, "NFTAuction: price too low");
        // Already bided
        if(auction.lastBidder != address(0)) {
            require(block.timestamp <= auction.endAt, "NFTAuction: already ended");
            tokenToPay.safeTransfer(auction.lastBidder, auction.lastPrice);
        }

        tokenToPay.safeTransferFrom(msg.sender, address(this), _price);

        auction.lastPrice = _price;
        auction.lastBidder = msg.sender;
        
        emit NFTAuctionBid(_tokenId, _price, msg.sender);
    }

    function auctionEnd(uint _tokenId) public {
        Auction memory auction = nftIdToAuction[_tokenId];

        require(auction.used, "NFTAuction: Auction uncreated");
        require(block.timestamp > auction.endAt, "NFTAuction: Auction is not over yet");
        require(msg.sender == auction.lastBidder, "NFTAuction: You're not the highest bidder");

        delete nftIdToAuction[_tokenId];
        bool isChanged;
        uint16 index;
        (isChanged, index) = nftInAuctionArr.unsafeDelete(index);
        if(isChanged) {
            uint id = nftInAuctionArr[index];
            nftIdToAuction[id].arrIndex = index;
        }

        // TODO 比例分成
        uint amountToSeller = auction.lastPrice * 2 / 100; // 2%
        uint amountToCbdBuybackPool = auction.lastPrice * 80 / 100; // 80%
        uint amountToReserveFundPool = auction.lastPrice * 15 / 100; // 15%
        uint amountToPlatformPool = auction.lastPrice - amountToSeller - amountToCbdBuybackPool - amountToReserveFundPool; // 3%

        tokenToPay.safeTransfer(auction.seller, amountToSeller);
        tokenToPay.safeTransfer(cbdBuybackPool, amountToCbdBuybackPool);
        tokenToPay.safeTransfer(reserveFundPool, amountToReserveFundPool);
        tokenToPay.safeTransfer(platformPool, amountToPlatformPool);

        mining.transferCreation(_tokenId, msg.sender);
        emit NFTAuctionEnded(_tokenId, auction.lastPrice, msg.sender);
    }

    function setDefaultPrice(uint128 _price) public {
        defaultPrice = _price;
    }

    // get the amount of instanted nft in auction.
    function getInstantedLength() public view returns(uint) {
        return nftInAuctionArr.length;
    }
    
    function setPlatformCreator(address _platformCreator) public onlyOwner {
        platformCreator = _platformCreator;
    }

    function setCbdBuybackPool(address _cbdBuybackPool) public onlyOwner {
        cbdBuybackPool = _cbdBuybackPool;
    }

    function setReserveFundPool(address _reserveFundPool) public onlyOwner {
        reserveFundPool = _reserveFundPool;
    }

    function setPlatformPool(address _platformPool) public onlyOwner {
        platformPool = _platformPool;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
            override external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // function setFactory(address _factory) public onlyOwner {
    //     nftFactory = IPeriod(_factory);
    // }
}