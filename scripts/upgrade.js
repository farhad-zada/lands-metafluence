// import { ethers, upgrades } from "hardhat";
async function main() {
  const LAND_ADDR = "0xb20b17a146d0ceaaaec707a3703d790139f747bf";
  const Land = await ethers.getContractFactory("Land");

  const landv3 = await upgrades.upgradeProxy(LAND_ADDR, Land);
  // Start deployment, returning a promise that resolves to a contract object
  console.log("Contract upgraded to address:", landv3.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
