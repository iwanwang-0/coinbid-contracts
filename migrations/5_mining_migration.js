const Mining = artifacts.require('Mining');
const CoinBid = artifacts.require('CoinBid');
const UintArray = artifacts.require('UintArray');
const NFTFactory = artifacts.require('NFTFactory');
const CoinBidCreation = artifacts.require('CoinBidCreation');
const BigNumber=require("bignumber.js");

module.exports = async function(deployer) {
    var coinbid = await CoinBid.deployed();
    var nft = await CoinBidCreation.deployed();
    var periodMana = await NFTFactory.deployed();
    await deployer.deploy(UintArray);
    await deployer.link(UintArray, Mining);
    await deployer.deploy(Mining, coinbid.address, periodMana.address, nft.address);
    var mining = await Mining.deployed();
    // var tx = await coinbid.mint(mining.address, new BigNumber(100000000000000000000000000));
    var tx = await coinbid.transfer(mining.address, new BigNumber(100000000000000000000000000));
    console.log('CBD token transfer: ' + tx.tx);
}