const CoinBid = artifacts.require('CoinBid');

module.exports = function(deployer) {
    deployer.deploy(CoinBid);
}