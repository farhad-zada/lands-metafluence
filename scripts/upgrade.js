const { ethers, upgrades } = require("hardhat");
async function main() {
  const LandV2 = await ethers.getContractFactory("LandV2");

  const landV2 = await upgrades.upgradeProxy(
    "0xb20b17a146D0CeAAAeC707a3703d790139f747bf",
    LandV2
  );
  await landV2.deployed();
  console.log(`Contract {${landV2.address}} upgraded! ✨`, landV2.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
