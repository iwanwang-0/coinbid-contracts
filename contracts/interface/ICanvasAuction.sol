// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICanvasAuction {
    function buy(uint16 _amount) external;
    function popOne(address _theOwner) external returns(bool);
    function getMyAmount(address _theOwner) external view returns(uint);
    function getAmountLeft() external view returns(uint);
}