const NFTFactory = artifacts.require('NFTFactory');

module.exports = function(deployer, network) {
    var period;
    if(network == 'mainnet') {
        period = 3600 * 24; // 1 day
    } else if(network == 'kovan') {
        period = 3600; // 1 hour
    } else if(network == 'ganache') {
        period = 60; // 1 minute
    } else {
        period = 3600 * 24; // 1 day
    }
    var amountPerPeriod = 520;
    deployer.deploy(NFTFactory, period, amountPerPeriod);
}