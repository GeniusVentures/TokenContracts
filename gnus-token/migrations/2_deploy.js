const GNUSToken = artifacts.require('GNUSToken');

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(GNUSToken);
};