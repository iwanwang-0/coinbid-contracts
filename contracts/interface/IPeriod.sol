// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPeriod {

    function getPeriod() external view returns(uint);
    function getPeriodStart() external view returns(uint);
    function getCurPeriod() external view returns(uint);
    function getCurPeriodStartAt() external view returns(uint);
    function getAmountPerPeriod() external view returns(uint16);
    function getTotalAmount() external view returns(uint);
}