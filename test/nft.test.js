const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("MyNFT", function () {
  let nft
  let owner, addr1, addr2

  beforeEach(async function () {
    ;[owner, addr1, addr2] = await ethers.getSigners()

    const NFT = await ethers.getContractFactory("MyNFT")
    console.log("部署中...")
    nft = await NFT.deploy()
    console.log("nft.address =", nft.target) // 地址已经出来了 ✅
    console.log("等待确认...")
    await nft.waitForDeployment() // 等几秒，直到区块确认
    console.log("✅ 部署成功！")
  })

  it("Should mint an NFT to user1", async function () {
    await nft.mintNFT(addr1.address)
    expect(await nft.ownerOf(1)).to.equal(addr1.address)
  })
  it("Should increase tokenId when minting", async function () {
    await nft.mintNFT(addr1.address)
    await nft.mintNFT(addr2.address)

    expect(await nft.ownerOf(1)).to.equal(addr1.address)
    expect(await nft.ownerOf(2)).to.equal(addr2.address)
  })

  it("Should only allow owner to mint", async function () {
    await expect(nft.connect(addr1).mintNFT(addr1.address)).to.be.revertedWithCustomError(nft, "OwnableUnauthorizedAccount").withArgs(addr1.address)
  })
})
