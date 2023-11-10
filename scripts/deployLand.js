const { ethers } = require("hardhat");

// import { ethers, upgrades } from "hardhat";
async function main() {
  const land = await ethers.deployContract("Land");
  // Start deployment, returning a promise that resolves to a contract object

  console.log("Contract deployed to address:", land.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
