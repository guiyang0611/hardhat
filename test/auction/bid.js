async function main() {
  const auctionAddress = "0xYourAuctionContractAddressHere" // 替换为实际的拍卖合约地址
  const VALUE = ethers.parseEther("0.01") // 出价 0.01 ETH

  const auction = await ethers.getContractAt("Auction", auctionAddress)
  const tx = await auction.bid({ value: VALUE }) // 以太币的数量
  await tx.wait()
  console.log("✅ 出价成功！")
  console.log("交易哈希:", tx.hash)
}

main()
