// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICoinBidCreation is IERC721 {
    function safeMint(address to, uint256 tokenId, string memory _tokenURI, address creator) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function creatorOf(uint256 tokenId) external view returns(address);
}