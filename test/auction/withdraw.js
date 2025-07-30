async function main() {
  const auctionAddress = "0xYourAuctionContractAddressHere" // 替换为实际的拍卖合约地址
  const auction = await ethers.getContractAt("Auction", auctionAddress)
  const tx = await auction.withdraw()
  await tx.wait()
  console.log("✅ 退款成功！")
  console.log("交易哈希:", tx.hash)
}

main()
