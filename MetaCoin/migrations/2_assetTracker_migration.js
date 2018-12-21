const ERC721 = artifacts.require('ERC721');
const ERC721Token = artifacts.require('ERC721Token');
const assetTracker = artifacts.require('assetTracker');

module.exports = function(deployer) {
	deployer.deploy(assetTracker);
}