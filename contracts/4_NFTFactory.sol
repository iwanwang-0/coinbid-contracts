// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IPeriod.sol";

contract NFTFactory is Ownable, IPeriod {

    uint private period;
    uint private periodStart;
    uint16 private amountPerPeriod;

    constructor(uint _period/*, uint _periodStart*/, uint16 _amountPerPeriod) {
        period = _period;
        periodStart = block.timestamp;//_periodStart;
        amountPerPeriod = _amountPerPeriod;
    }

    function getTotalAmount() override public view returns(uint) {
        return ((block.timestamp - periodStart) / period + 1) * amountPerPeriod;
    }

    // get the current period id
    function getCurPeriod() override public view returns(uint) {
        return (block.timestamp - periodStart) / period;
    }

    function getCurPeriodStartAt() override public view returns(uint) {
        uint curPeriod = getCurPeriod();
        uint startAt = startTimeAt(curPeriod);
        return startAt;
    }

    function getPeriod() override external view returns(uint) {
        return period;
    }

    function getPeriodStart() override external view returns(uint) {
        return periodStart;
    }

    function getAmountPerPeriod() override external view returns(uint16) {
        return amountPerPeriod;
    }

    // get the start time of a period.
    function startTimeAt(uint _periodId) public view returns(uint) {
        return _periodId * period + periodStart;
    }

    // to check if the canvas id and period id are valid.
    // function checkValid(uint _canvasId, uint _periodId) public view returns(bool) {
    //     if(_canvasId <= 0 || _periodId == 0) {
    //         return false;
    //     }

    //     uint currPeriod = getCurPeriod();
    //     if(_periodId > currPeriod) {
    //         return false;
    //     }
    //     // TODO....

    //     return true;
    // }

}