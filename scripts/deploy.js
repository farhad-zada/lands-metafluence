async function main() {
    const Land = await ethers.getContractFactory("Land")
  
    // Start deployment, returning a promise that resolves to a contract object
    const land = await Land.deploy()
    await land.deployed()
    console.log("Contract deployed to address:", land.address)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })

    // token address 0x6a3443193D0171a12595525510B3068a635625c3