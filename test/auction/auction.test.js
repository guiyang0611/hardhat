async function main() {
  const nftAddress = "0xDae164B815AcD586028632e3b6BB563704B20724"
  const auctionAddress = "0xYourAuctionContractAddressHere" // 替换为实际的拍卖合约地址
  const tokenId = 1
  const nft = await ethers.getContractAt("MyNFT", nftAddress)
  const tx = await nft.approve(auctionAddress, tokenId)
  await tx.wait()
  console.log("✅ NFT 已授权给拍卖合约")
}

main()
