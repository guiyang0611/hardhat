async function main() {
  const nftAddress = "0xDae164B815AcD586028632e3b6BB563704B20724"
  const factoryAddress = "0x2F785890168F5E871E3E73FaF2A52c31E203c46b"
  const tokenId = 1
  const biddingTime = 3600 // 1小时

  console.log("正在创建拍卖...")
  const auctionFactory = await ethers.getContractAt("AuctionFactory", factoryAddress)
  const nft = await ethers.getContractAt("MyNFT", nftAddress)

  const tx = await auctionFactory.createAuction(nftAddress, tokenId, biddingTime)
  console.log("交易已发送，等待确认...")

  const receipt = await tx.wait()
  const event = receipt.logs.find((log) => {
    try {
      // 确保日志来自工厂合约
      if (log.address !== factoryAddress) {
        return false
      }
      // 使用工厂合约的 ABI 解析日志
      const parsed = auctionFactory.interface.parseLog(log)
      return parsed.name === "AuctionCreated"
    } catch (e) {
      return false // 无法解析的日志忽略
    }
  })

  if (!event) {
    throw new Error("未找到 AuctionCreated 事件")
  }
  const auctionAddress = event.args.auction
  console.log("✅ 创建拍卖合约成功！")
  console.log("拍卖合约地址:", auctionAddress)
  console.log("交易哈希:", tx.hash)

  //开始授权
  console.log("正在授权 NFT 给拍卖合约...")
  const approveTx = await nft.approve(auctionAddress, tokenId)
  await approveTx.wait()
  console.log("✅ NFT 已授权给拍卖合约")
}

main().catch(console.error)
