const NFTSwap = artifacts.require('NFTSwap');
const CoinBidCreation = artifacts.require('CoinBidCreation');
const Mining = artifacts.require('Mining');
const TetherUSD = artifacts.require('TetherUSD');
const UintArray = artifacts.require('UintArray');

module.exports = async function(deployer, network) {
    const accounts = await web3.eth.getAccounts();

    // USDT Address
    var usdtAddr;
    if(network == 'mainnet') {
        usdtAddr = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    } else if(network == 'kovan') {
        usdtAddr = "0xEBA2a7912bC80edf9966648ae0c43190CDDffAeC";
    } else {// ganache, we need to deploy a erc20 token contract, which will named USDT.
        // await deployer.deploy(TetherUSD);
        var usdt = await TetherUSD.deployed();
        usdtAddr = usdt.address;
    }

    // TODO Set the real pool address.
    // trust fund pool
    var pool = accounts[1];
    // nft contract
    var nft = await CoinBidCreation.deployed();
    // Mining contract
    var mining = await Mining.deployed();

    await deployer.link(UintArray, NFTSwap);
    await deployer.deploy(NFTSwap, usdtAddr, pool, nft.address, mining.address);
    var nftSwap = await NFTSwap.deployed();

    tx = await mining.addGovernance(nftSwap.address);
    console.log('Mining add governance: ' + tx.tx);

    tx = await mining.setSwap(nftSwap.address);
    console.log("Mining set NFTSwap address: " + tx.tx);
}