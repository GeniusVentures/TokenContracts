const GeniusTokens = artifacts.require('GeniusAI');

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(GeniusAI);
};