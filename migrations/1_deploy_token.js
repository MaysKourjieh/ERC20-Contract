const ERC20 = artifacts.require("ERC20");

module.exports = async function(deployer) {
  // deployment steps
  await deployer.deploy(ERC20, "My Token", "MTK");
};