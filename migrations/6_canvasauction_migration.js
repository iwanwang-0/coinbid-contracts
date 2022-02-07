const CanvasAuction = artifacts.require('CanvasAuction');
const CoinBid = artifacts.require('CoinBid');
const NFTFactory = artifacts.require('NFTFactory');
const BigNumber=require("bignumber.js");

module.exports = async function(deployer) {
    // CBD token contract
    var cbd = await CoinBid.deployed();
    // canvas price
    var canvasPrice = new BigNumber(100000000000000000000); // 100 CBD
    // period manager
    var nftFactory = await NFTFactory.deployed();

    await deployer.deploy(CanvasAuction, cbd.address, canvasPrice, nftFactory.address);
}