// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INFTSwap{
    // function getOrders() external view returns(NFTInfo[] memory);
    // function createOrder(uint _tokenId, uint _price) external;
    // function cancelOrder(uint _tokenId) external;
    // function updateOrder(uint _tokenId, uint _price) external;
    // function buy(uint _tokenId) external;
    function isInOrder(uint _tokenId) external view returns(bool);
}