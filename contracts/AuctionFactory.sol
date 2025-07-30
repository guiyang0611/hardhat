// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Auction.sol";

/**
 * @title AuctionFactory
 * @dev 创建和管理多个拍卖合约
 */
contract AuctionFactory {
    struct AuctionInfo {
        address auction; // 拍卖合约地址
        address nftAddress; // NFT 合约地址
        uint256 tokenId; // NFT tokenId
        uint256 minPriceUSD; // 底价（USD，6 位小数）
    }
    // 拍卖合约信息(NFT地址 + TokenId + 拍卖合约地址)
    mapping(address => mapping(uint256 => address)) public getAuctionByNFT;

    AuctionInfo[] public allAuctions;

    uint256 public auctionCount;

    address public owner;

    event AuctionCreated(
        address indexed auction,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 biddingTime,
        address seller,
        uint256 minPriceUSD
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev 创建新的拍卖合约
     * @param _nftAddress NFT 合约地址
     * @param _tokenId NFT tokenId
     * @param _biddingTime 竞拍时间（秒）
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _biddingTime,
        uint256 _minPriceUSD
    ) external returns (address) {
        require(_biddingTime > 0, "Bidding time must be greater than zero");
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "You must owner the NFT to create an auction"
        );
        require(
            getAuctionByNFT[_nftAddress][_tokenId] == address(0),
            "Auction already exists for this NFT"
        );
        // 创建新的拍卖合约
        Auction auction = new Auction(
            _nftAddress,
            _tokenId,
            _biddingTime,
            _minPriceUSD
        );
        address newAuction = address(auction);
        // 添加到拍卖合约列表
        allAuctions.push(
            AuctionInfo({
                auction: newAuction,
                nftAddress: _nftAddress,
                tokenId: _tokenId,
                minPriceUSD: _minPriceUSD
            })
        );
        auctionCount++;
        getAuctionByNFT[_nftAddress][_tokenId] = newAuction;
        // 触发创建事件
        emit AuctionCreated(
            newAuction,
            _nftAddress,
            _tokenId,
            _biddingTime,
            msg.sender,
            _minPriceUSD
        );
        return newAuction;
    }

    /**
     * @dev 获取拍卖总数
     */
    function allAuctionsLength() external view returns (uint256) {
        return allAuctions.length;
    }

    // --- 管理功能（可选）---
    // 暂停、升级模板、提取手续费等
}
