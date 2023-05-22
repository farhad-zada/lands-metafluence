const { ethers, upgrades } = require("hardhat");
async function main() {
  const Land = await ethers.getContractFactory("Land");

  const land = await upgrades.deployProxy(Land);
  // Start deployment, returning a promise that resolves to a contract object
  await land.deployed();
  console.log("Contract deployed to address:", land.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
