// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 public tokenIdCounter;

    constructor() ERC721("MyNFT", "MFT") Ownable(msg.sender) {}

    function mintNFT(address to) external onlyOwner returns (uint256) {
        uint256 newTokenId = ++tokenIdCounter;
        _safeMint(to, newTokenId);
        return newTokenId;
    }
}
