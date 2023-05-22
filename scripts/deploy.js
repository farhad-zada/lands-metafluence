const { ethers, upgrades } = require("hardhat");
async function main() {
  const Levels = await ethers.getContractFactory("Levels");

  const levels = await upgrades.deployProxy(Levels);
  // Start deployment, returning a promise that resolves to a contract object
  await levels.deployed();
  console.log("Contract deployed to address:", levels.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
