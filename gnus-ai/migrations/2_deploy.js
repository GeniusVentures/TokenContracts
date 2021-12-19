const PolyGNUSToken = artifacts.require('PolyGNUSToken');

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(PolyGNUSToken);
};