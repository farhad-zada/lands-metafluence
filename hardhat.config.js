require("dotenv").config();

require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  mocha: 20000,

  networks: {
    hardhat: {
      chainId: 31337,
      gasPrice: 20000000000, // 20 gwei
    },
    bnb: {
      url: process.env.BNB_RPC,
      chainId: 97,
      accounts: [process.env.PKEY],
      gasPrice: 30000000000, // 20 gwei
    },
    plg: {
      url: process.env.PLG_RPC,
      chainId: 80001,
      accounts: [process.env.PKEY],
      gasPrice: 2000000000, // 20 gwei
    },
    bsc: {
      url: process.env.BSC_RPC,
      chainId: 56,
      accounts: [process.env.PKEY],
    },
  },
  defaultNetwork: "hardhat",
};
