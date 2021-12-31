const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const PolyGNUSToken = artifacts.require('PolyGNUSToken');
/* const BoxV2 = artifacts.require('BoxV2');

module.exports = async function (deployer) {
    const existing = await Box.deployed();
    const instance = await upgradeProxy(existing.address, BoxV2, { deployer });
    console.log("Upgraded", instance.address);
}; */