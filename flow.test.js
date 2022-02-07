const NFTAuction = artifacts.require('NFTAuction');

module.exports = async function(deployer) {
    var nftAuction = await NFTAuction.deployed();
    var auctionArr, length;
    var a = await nftAuction.getNFTInAuction(10, 1);
    console.log("return amount: " + auctionArr.length);
    console.log("total amount: " + length);
}