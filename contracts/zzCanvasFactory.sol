// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ICanvasFactory.sol";

contract CanvasFactory is Ownable, ICanvasFactory {

    // period => amount, period id start at 1
    mapping (uint=>uint) public canvasAmountMap;
    uint[] periodsSetArr;
    uint public period;
    uint public periodStart;
    // 最近几个周期内的未实例化的画布仍然有效
    uint public recentNumPeriod;

    // struct PeriodInfo {
    //     uint id;
    //     // uint[] canvasIdArr;
    //     uint startCanvasId;
    //     uint canvasAmount;
    // }

    constructor() {
        // start at 1
        canvasAmountMap[1] = 10;
        periodsSetArr.push(1);
        period = 1 minutes;
        periodStart = block.timestamp;
        recentNumPeriod = 7;
    }

    // get the recent periods.
    // the recent number specified by "recentNumPeriod"
    function getRecentPeriods() override public view returns(PeriodInfo[] memory) {
        uint curPeriod = getCurPeriod();
        uint start;
        if((curPeriod + 1) > recentNumPeriod) {
            start = (curPeriod + 1) - recentNumPeriod;
        } else {
            start = 1;
        }
        return getPeriods(start, curPeriod + 1);
    }

    // function getLastPeriodStartTime() public view returns(uint) {
    //     uint numPeriods = getCurPeriod();
    //     uint lastPeriodStartTime = periodStart + (numPeriods * period);
    //     return lastPeriodStartTime;
    // }

    // get the current period id
    function getCurPeriod() override public view returns(uint) {
        return (block.timestamp - periodStart) / period + 1;
    }

    // get the period by period id
    // function getPeriod(uint _periodId) public view returns(uint) {
    //     uint i;
    //     for(i = periodsSetArr.length - 1; i >= 0; i--) {
    //         if(_periodId >= periodsSetArr[i]) {
    //             break;
    //         }
    //     }
    //     return canvasAmountMap[periodsSetArr[i]];
    // }

    // Get the periods that specified start and end.
    function getPeriods(uint _start, uint _end) override public view returns(PeriodInfo[] memory) {
        uint amountUntilStart;
        uint arrIndex;
        (amountUntilStart, arrIndex) = getCanvasAmountUntil(_start);

        // canvas id start at 1
        uint currCanvasId = amountUntilStart;

        PeriodInfo[] memory infoArr = new PeriodInfo[](_end - _start + 1);

        uint periodIndex = 0;

        for(uint i = arrIndex; i < periodsSetArr.length; i++) {
            if(periodsSetArr[i] > _end) {
                break;
            }

            uint lastMax = max(_start, periodsSetArr[i]);
            uint nextMin;

            // if it is the last one?
            if((periodsSetArr.length - 1) <= i) {
                nextMin = _end;
            } else {
                uint next = periodsSetArr[i + 1];
                nextMin = min(next, _end);
            }

            uint curr = periodsSetArr[i];

            for(uint j = lastMax; j < nextMin; j++) {
                uint periodId = j;

                uint amount = canvasAmountMap[curr];

                // uint[] memory canvasIdArr = new uint[](amount);
                // for(uint k = 0; k < amount; k++) {
                //     currCanvasId = currCanvasId + 1;
                //     canvasIdArr[k] = currCanvasId;
                // }

                PeriodInfo memory info = PeriodInfo(periodId, currCanvasId + 1, amount);
                infoArr[periodIndex] = info;
                periodIndex += 1;
                currCanvasId = currCanvasId + amount;
            }
        }

        return infoArr;
    }

    // get the total canvas amount until the specified period
    function getCanvasAmountUntil(uint _periodId) override public view returns(uint, uint) {
        uint total = 0;
        uint arrIndex = 0;
        for(uint i = 0; i < periodsSetArr.length; i++) {
            if(periodsSetArr[i] > _periodId) {
                break;
            }
            uint nextMin;
            // if it is the last one?
            if((periodsSetArr.length - 1) <= i) {
                nextMin = _periodId;
            } else {
                uint next = periodsSetArr[i + 1];
                nextMin = min(next, _periodId);
            }
            uint curr = periodsSetArr[i];
            total = total + canvasAmountMap[curr] * (nextMin - curr);
            arrIndex = i;
        }
        return (total, arrIndex);
    }

    // to check if the canvas id and period id are valid.
    function checkValid(uint _canvasId, uint _periodId) override public view returns(bool) {
        if(_canvasId <= 0 || _periodId == 0) {
            return false;
        }

        uint currPeriod = getCurPeriod();
        if(_periodId > currPeriod) {
            return false;
        }
        if(_periodId < (currPeriod - recentNumPeriod + 1)) {
            return false;
        }

        uint canvasId;
        uint arrIndex;
        (canvasId, arrIndex) = getCanvasAmountUntil(_periodId + 1);

        uint canvasAmount = canvasAmountMap[periodsSetArr[arrIndex]];

        uint start = canvasId - canvasAmount + 1;
        uint end = canvasId;

        if(_canvasId < start) {
            return false;
        }
        if(_canvasId > end) {
            return false;
        }

        return true;
    }

    // get the start time of a period.
    function startTimeAt(uint _periodId) override public view returns(uint) {
        return (_periodId - 1) * period + periodStart;
    }

    // set the canvas amount of every period
    function setCanvasAmount(uint _amount) public onlyOwner {
        uint nextPeriod = getCurPeriod() + 1;
        canvasAmountMap[nextPeriod] = _amount;
        
        //有可能在同一周期设置了两次
        uint lastone = periodsSetArr[periodsSetArr.length -1];
        if(nextPeriod > lastone) {
            periodsSetArr.push(nextPeriod);
        }
    }

    // set the recent number of period
    function setRecentNumPeriod(uint _recentNumPeriod) public onlyOwner {
        recentNumPeriod = _recentNumPeriod;
    }

    function max(uint a, uint b) internal pure returns(uint) {
        if(a > b) {
            return a;
        } else {
            return b;
        }
    }

    function min(uint a, uint b) internal pure returns(uint) {
        if(a > b) {
            return b;
        } else {
            return a;
        }
    }

}