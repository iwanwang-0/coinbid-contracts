const NFTAuction = artifacts.require('NFTAuction');
const NFTFactory = artifacts.require('NFTFactory');
const CoinBidCreation = artifacts.require('CoinBidCreation');
const Mining = artifacts.require('Mining');
const CanvasAuction = artifacts.require('CanvasAuction');
const TetherUSD = artifacts.require('TetherUSD');
const UintArray = artifacts.require('UintArray');

module.exports = async function(deployer, network) {
    const accounts = await web3.eth.getAccounts();

    var nftFactory = await NFTFactory.deployed();
    // USDT Address
    var usdtAddr;

    // The platform creator.
    var platformCreator = accounts[1];
    // CBD buy back account.
    var cbdBuybackPool = accounts[2];
    // strategic reserve fund pool.
    var reserveFundPool = accounts[3];
    // Platform operating pool.
    var platformPool = accounts[4];
    
    if(network == 'mainnet') {
        usdtAddr = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
        platformCreator = ""; // TODO set address
        cbdBuybackPool = "";
        reserveFundPool = "";
        platformPool = "";
    } else if(network == 'kovan') {
        usdtAddr = "0xEBA2a7912bC80edf9966648ae0c43190CDDffAeC";
    } else {// ganache, we need to deploy a erc20 token contract, which will named USDT.
        await deployer.deploy(TetherUSD);
        var usdt = await TetherUSD.deployed();
        usdtAddr = usdt.address;
    }

    // nft contract
    var nft = await CoinBidCreation.deployed();
    // Mining contract
    var mining = await Mining.deployed();
    // canvas auction contract
    var canvasAuction = await CanvasAuction.deployed();
    // 211 usdt
    var defaultPrice = 211000000;

    await deployer.link(UintArray, NFTAuction);

    await deployer.deploy(NFTAuction, 
                        nftFactory.address, 
                        usdtAddr, 
                        platformCreator, 
                        cbdBuybackPool, 
                        reserveFundPool, 
                        platformPool, 
                        nft.address, 
                        mining.address, 
                        canvasAuction.address, 
                        defaultPrice);
    var nftAuction = await NFTAuction.deployed();
    
    var minterRole = await nft.MINTER_ROLE();
    var tx = await nft.grantRole(minterRole, nftAuction.address);
    console.log('NFT token grant role: ' + tx.tx);

    tx = await canvasAuction.addGovernance(nftAuction.address);
    console.log('CanvasAuction add governance: ' + tx.tx);

    tx = await mining.addGovernance(nftAuction.address);
    console.log('Mining add governance: ' + tx.tx);
}