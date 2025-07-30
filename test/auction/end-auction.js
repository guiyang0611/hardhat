async function main() {
  const auctionAddress = "0xYourAuctionContractAddressHere" // 替换为实际的拍卖合约地址
  const auction = await ethers.getContractAt("Auction", auctionAddress)
  const tx = await auction.endAuction() // 以太币的数量
  await tx.wait()
  console.log("✅ 拍卖已结束！")
  console.log("NFT 已转移给最高出价者，钱已打给卖家")
}

main()
