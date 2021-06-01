const GeniusTokens = artifacts.require('GeniusTokens');

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(GeniusTokens);
};