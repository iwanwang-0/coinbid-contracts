const CoinBidCreation = artifacts.require('CoinBidCreation');

module.exports = function(deployer) {
    deployer.deploy(CoinBidCreation);
}