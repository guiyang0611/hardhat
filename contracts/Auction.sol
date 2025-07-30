// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Auction is ReentrancyGuard {
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
    // 底价（USD，6 位小数）
    uint256 public minPriceUSD;
    // 竞拍结束时间
    uint256 public endTime;
    // 竞拍是否结束
    bool public ended = false;
    // 竞拍退款池
    mapping(address => uint256) public pendingReturns;
    // 价格喂价
    AggregatorV3Interface internal priceFeed;

    // 事件
    event Bid(address indexed bidder, uint256 amountETH, uint256 amountUSD);
    event Withdrawn(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amountETH, uint256 amountUSD);
    event MinPriceSet(uint256 minPriceUSD);

    constructor(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _biddingTime,
        uint256 _minPriceUSD
    ) {
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        seller = payable(msg.sender);
        endTime = block.timestamp + _biddingTime;
        minPriceUSD = _minPriceUSD;
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
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

    // --- Chainlink 价格相关函数 ---

    /**
     * @dev 获取最新 ETH/USD 价格
     * @return price 价格（单位：USD，6 位小数）
     */
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Chainlink Sepolia ETH/USD 有 8 位小数
        // 我们转换为 6 位小数：乘以 1e6 / 1e8 = 1e-2
        return uint256(price) / 1e2; // 即除以 100
    }

    /**
     * @dev 将 ETH 金额转换为 USD
     * @param ethAmount ETH 金额（wei）
     * @return USD 金额（6 位小数）
     */
    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getEthPrice(); // 现在是 6 位小数
        // ethAmount (wei) * price (6 位) / 1e18 => USD (6 位)
        return (ethAmount * ethPrice) / 1e18;
    }

    /**
     * @dev 将 USD 转换为 ETH（用于比较）
     * @param usdAmount USD 金额（6 位小数）
     * @return ETH 金额（wei）
     */
    function convertUsdToEth(uint256 usdAmount) public view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        return (usdAmount * 1e18) / ethPrice;
    }

    // 出价
    function bid() public payable onlyBefore(endTime) {
        require(!ended, "Auction already ended");
        require(msg.value > 0, "Bid amount must be greater than zero");
        uint256 currentBidUsd = convertEthToUsd(msg.value);
        uint256 currentHighestBidUsd = convertEthToUsd(highestBid);
        // 检查是否达到最低 USD 价格
        if (minPriceUSD > 0) {
            require(
                currentBidUsd >= minPriceUSD,
                "Auction: bid below minimum price"
            );
        }
        // 比较 USD 价值
        require(
            currentBidUsd > currentHighestBidUsd,
            "Bid USD value not higher"
        );
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
        emit Bid(msg.sender, msg.value, currentBidUsd);
    }

    // 退款 非最高者出价可调用
    function withdraw() external nonReentrant returns (bool) {
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
        uint256 finalAmountUsd = convertEthToUsd(highestBid);
        emit AuctionEnded(highestBidder, highestBid, finalAmountUsd);
        // 将NFT转移给最高出价者
        if (highestBidder != address(0)) {
            // 将钱转给卖家
            seller.transfer(highestBid);
            IERC721(nftAddress).transferFrom(seller, highestBidder, tokenId);
        }
        // else: 无人出价，NFT 自然留在 seller 钱包，无需操作
        // 清空最高出价和最高出价者
        highestBid = 0;
        highestBidder = payable(address(0));
    }

    /**
     * @dev 取消拍卖
     */
    function cancelAuction() external {
        require(!ended, "Auction already ended");
        require(highestBidder == address(0), "Cannot cancel: bid exists");
        require(msg.sender == seller, "Not seller");
        ended = true;
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
