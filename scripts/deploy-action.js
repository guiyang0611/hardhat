const nftAddress = "0xDae164B815AcD586028632e3b6BB563704B20724"
const tokenId = 1
const endTime = 60 * 60 * 24 * 7 // 7 days in seconds

async function main() {
  const Action = await ethers.getContractFactory("Auction")
  const auction = await Action.deploy(nftAddress, tokenId, endTime)
  await auction.waitForDeployment()

  console.log("Auction deployed to:", auction.target)
  console.log("Auction address:", auction.target)
  console.log("Verify with:")
  console.log(`npx hardhat verify --network sepolia ${auction.target} ${nftAddress} ${tokenId} ${endTime}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
