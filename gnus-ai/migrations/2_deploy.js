const PolyGNUSToken = artifacts.require('PolyGNUSToken');

const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
    const instance = await deployProxy(PolyGNUSToken, { deployer });
    console.log('Deployed', instance.address);
}

