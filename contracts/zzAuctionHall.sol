// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "./interface/ICanvasFactory.sol";
// import "./interface/IMining.sol";

// contract AuctionHall is Ownable {

//     using SafeERC20 for IERC20;

//     ICanvasFactory canvasFactory;
//     IMining mining;

//     // Pay CBD Token
//     uint128 canvasStartingPrice;
//     uint64 canvasAuctionDuration;

//     // TODO set value
//     IERC20 cbd;
//     uint8 cbdDecimals = 18;

//     // Trust fund pool
//     address pool;

//     // Represents an auction on an canvas
//     struct CanvasAuction {
//         // Current owner of canvas
//         address seller;
//         uint128 lastPrice;
//         // Duration (in seconds) of auction
//         uint64 duration;
//         // Time when auction started
//         // NOTE: 0 if this auction has been concluded
//         uint startedAt;
//         address lastBidder;
//         bool used;
//         bool ended;
//     }

//     // Map from canvas ID to their corresponding auction.
//     mapping (uint256 => CanvasAuction) canvasIdToAuction;

//     event CanvasAuctionCreated(uint canvasId, uint256 startingPrice, uint256 duration);
//     event CanvasAuctionBid(uint canvasId, uint256 bidPrice, address bidder);
//     event CanvasAuctionEnded(uint canvasId, uint price, address buyer);
    
//     constructor(address _canvasFactory, address _mining, address _cbd, address _pool) {
//         canvasFactory = ICanvasFactory(_canvasFactory);
//         mining = IMining(_mining);
//         canvasStartingPrice = uint8(200) * uint8(10) ** cbdDecimals;
//         canvasAuctionDuration = 1 days;
//         cbd = IERC20(_cbd);
//         pool = _pool;
//     }

//     function createCanvasAuction(uint _canvasId, uint _periodId, uint128 _price) private {
//         require(canvasFactory.checkValid(_canvasId, _periodId), "AuctionHall: Invalid canvas id or period id");
//         require(_price > canvasStartingPrice, "AuctionHall: price too low");

//         uint periodStart = canvasFactory.startTimeAt(_periodId);
//         require(block.timestamp <= periodStart + canvasAuctionDuration);

//         cbd.safeTransferFrom(msg.sender, address(this), _price);

//         CanvasAuction memory auction = CanvasAuction(address(this), _price, canvasAuctionDuration, 
//                         periodStart, address(msg.sender), true, false);
//         canvasIdToAuction[_canvasId] = auction;

//         emit CanvasAuctionCreated(_canvasId, canvasStartingPrice, canvasAuctionDuration);
//         emit CanvasAuctionBid(_canvasId, _price, msg.sender);
//     }

//     function bidCanvas(uint _canvasId, uint128 _price) private {
//         CanvasAuction storage auction = canvasIdToAuction[_canvasId];

//         require(_price > auction.lastPrice, "AuctionHall: price too low");
//         require(block.timestamp <= auction.startedAt + canvasAuctionDuration, "AuctionHall: already ended");

//         cbd.safeTransferFrom(address(this), auction.lastBidder, auction.lastPrice);
//         cbd.safeTransferFrom(msg.sender, address(this), _price);

//         auction.lastPrice = _price;
//         auction.lastBidder = msg.sender;
        
//         emit CanvasAuctionBid(_canvasId, _price, msg.sender);
//     }

//     function bidCanvas(uint _canvasId, uint _periodId, uint128 _price) public {
//         if(canvasIdToAuction[_canvasId].used) {
//             // already created
//             bidCanvas(_canvasId, _price);
//         } else {
//             // not created yet, needs to create
//             createCanvasAuction(_canvasId, _periodId, _price);
//         }
//     }

//     function canvasAuctionEnd(uint _canvasId) public {
//         CanvasAuction storage auction = canvasIdToAuction[_canvasId];

//         require(auction.used, "AuctionHall: Auction uncreated");
//         require(block.timestamp > (auction.startedAt + auction.duration), "AuctionHall: Auction is not over yet");
//         require(msg.sender == auction.lastBidder, "AuctionHall: You're not the highest bidder");
//         require(!auction.ended, "AuctionHall: Auction already ended");

//         auction.ended = true;
//         cbd.safeTransferFrom(address(this), pool, auction.lastPrice);
//         mining.transferCanvas(_canvasId, msg.sender);
//         emit CanvasAuctionEnded(_canvasId, auction.lastPrice, msg.sender);
//     }

//     function getCanvasAuctions() public view returns(CanvasAuction[] memory) {
//         ICanvasFactory.PeriodInfo[] memory periodArr = canvasFactory.getRecentPeriods();
//         CanvasAuction[] memory auctionArr = new CanvasAuction[](periodArr.length);

//         uint32 arrIndex = 0;

//         for(uint i = 0; i < periodArr.length; i++) {
//             ICanvasFactory.PeriodInfo memory periodInfo = periodArr[i];
//             uint periodStart = canvasFactory.startTimeAt(periodInfo.id);
//             for(uint j = 0; j < periodInfo.canvasAmount; j++) {
//                 uint canvasId = periodInfo.startCanvasId + j;
//                 CanvasAuction memory auction;
//                 if(canvasIdToAuction[canvasId].used) {
//                     auction = canvasIdToAuction[canvasId];
//                 } else {
//                     auction = CanvasAuction(address(this), 
//                         canvasStartingPrice, canvasAuctionDuration, 
//                         periodStart, address(this), false, false);
//                 }
//                 auctionArr[arrIndex] = auction;
//                 arrIndex ++;
//             }
//         }

//         return auctionArr;
//     }

//     function setCanvasFactory(address _canvasFactory) external onlyOwner {
//         canvasFactory = ICanvasFactory(_canvasFactory);
//     }

//     function setMining(address _mining) external onlyOwner {
//         mining = IMining(_mining);
//     }

//     function setCBD(address _cbd) external {
//         cbd = IERC20(_cbd);
//     }

//     function setPool(address _pool) external {
//         pool = _pool;
//     }
// }