// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICanvasFactory {

    struct PeriodInfo {
        uint id;
        // uint[] canvasIdArr;
        uint startCanvasId;
        uint canvasAmount;
    }

    // get the recent periods.
    // the recent number specified by "recentNumPeriod"
    function getRecentPeriods() external view returns(PeriodInfo[] memory);

    // get the current period id
    function getCurPeriod() external view returns(uint);

    // Get the periods that specified start and end.
    function getPeriods(uint _start, uint _end) external view returns(PeriodInfo[] memory);

    // get the total canvas amount until the specified period
    function getCanvasAmountUntil(uint _periodId) external view returns(uint, uint);

    // to check if the canvas id and period id are valid.
    function checkValid(uint _canvasId, uint _periodId) external view returns(bool);

    // get the start time of a period.
    function startTimeAt(uint _periodId) external view returns(uint);
}