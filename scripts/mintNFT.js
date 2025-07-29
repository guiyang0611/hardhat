async function main() {
  const contractAddress = "0xDae164B815AcD586028632e3b6BB563704B20724"
  const nft = await ethers.getContractAt("MyNFT", contractAddress)
  const [owner] = await ethers.getSigners()
  console.log("合约所属账户地址:", owner.address)
  const toAddress = "0x2F785890168F5E871E3E73FaF2A52c31E203c46b"
  console.log("正在为", toAddress, "mint NFT...")
  const tx = await nft.mintNFT(toAddress)
  console.log("✅ Mint 成功！")
  console.log("交易哈希:", tx.hash)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
