async function main() {
  const AuctionFactory = await ethers.getContractFactory("AuctionFactory")
  const auctionFactory = await AuctionFactory.deploy()
  await auctionFactory.waitForDeployment()

  console.log("AuctionFactory deployed to:", auctionFactory.target)
  console.log("Verify with:")
  console.log(`npx hardhat verify --network sepolia ${auctionFactory.target}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
