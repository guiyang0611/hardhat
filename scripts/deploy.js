async function main() {
  // Hardhat 自动注入 ethers
  const NFT = await ethers.getContractFactory("MyNFT")
  const nft = await NFT.deploy()
  await nft.waitForDeployment()
  console.log("MyNFT deployed to:", nft.target)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
