// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AuctionHouse is ReentrancyGuard {
    // NFT合约地址
    address public nftAddress;
    // NFT的tokenId
    uint256 public tokenId;
    // 卖家地址
    address payable public seller;
    // 竞拍最高出价者地址
    address payable public highestBidder;
    // 最高出价
    uint256 public highestBid;
    // 竞拍结束时间
    uint256 public endTime;
    // 竞拍是否结束
    bool public ended = false;
    // 竞拍退款池
    mapping(address => uint256) public pendingReturns;

    // 事件
    event Bid(address indexed bidder, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    constructor(address _nftAddress, uint256 _tokenId, uint256 _biddingTime) {
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        seller = payable(msg.sender);
        endTime = block.timestamp + _biddingTime;
    }

    //修改器
    modifier onlyBefore(uint time) {
        require(block.timestamp < time, "Auction already ended");
        _;
    }

    modifier onlyAfter(uint time) {
        require(block.timestamp >= time, "Auction not yet ended");
        _;
    }

    // 出价
    function bid() public payable onlyBefore(endTime) {
        require(!ended, "Auction already ended");
        require(msg.value > 0, "Bid amount must be greater than zero");
        // 检查出价是否大于当前最高出价
        require(msg.value > highestBid, "There already is a higher bid");
        // 检查出价者地址是否为0
        if (highestBidder != address(0)) {
            // 将之前的出价存入退款池
            pendingReturns[highestBidder] += highestBid;
        }
        // 更新最高出价和最高出价者
        highestBidder = payable(msg.sender);
        // 更新最高出价
        highestBid = msg.value;
        // 触发出价事件
        emit Bid(msg.sender, msg.value);
    }

    // 退款 非最高者出价可调用
    function withdrawn() external nonReentrant returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        // 检查是否为最高出价者
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        // 清空退款池
        pendingReturns[msg.sender] = 0;
        // 转账
        payable(msg.sender).transfer(amount);
        // 触发提现事件
        emit Withdrawn(msg.sender, amount);
        return true;
    }

    //结束拍卖
    function endAuction() external nonReentrant onlyAfter(endTime) {
        require(!ended, "Auction already ended");
        require(msg.sender == seller, "Only seller can end the auction");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // 将NFT转移给最高出价者
        if (highestBidder != address(0)) {
            IERC721(nftAddress).transferFrom(seller, highestBidder, tokenId);
            // 将钱转给卖家
            seller.transfer(highestBid);
        }
        // else: 无人出价，NFT 自然留在 seller 钱包，无需操作
        // 清空最高出价和最高出价者
        highestBid = 0;
        highestBidder = payable(address(0));
    }

    // 获取拍卖信息
    function getAuctionInfo()
        external
        view
        returns (address, uint256, address, uint256, uint256, bool)
    {
        return (nftAddress, tokenId, highestBidder, highestBid, endTime, ended);
    }
}
