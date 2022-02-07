// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Governance.sol";
import "./interface/IPeriod.sol";
import "./interface/ICanvasAuction.sol";

contract CanvasAuction is Governance, ICanvasAuction {

    using SafeERC20 for IERC20;

    mapping(uint => uint16) periodToAmount;

    mapping(address => uint[]) private dateArrMap;
    // owner => (date => amount)
    mapping(address => mapping(uint => uint)) private amountMap;

    IERC20 public cbd;

    uint public canvasPrice;

    IPeriod public periodMana;

    uint public validTime;

    constructor(address _cbd, uint _canvasPrice, address _periodMana) {
        cbd = IERC20(_cbd);
        canvasPrice = _canvasPrice;
        periodMana = IPeriod(_periodMana);

        validTime = 30 days;
    }

    function buy(uint16 _amount) override public {
        uint currPeriod = periodMana.getCurPeriod();
        require((periodToAmount[currPeriod] + _amount) < periodMana.getAmountPerPeriod(),
            "CanvasAuction: There is not enough canvas left.");

        cbd.safeTransferFrom(msg.sender, address(this), canvasPrice * _amount);
        dateArrMap[msg.sender].push(block.timestamp);
        amountMap[msg.sender][block.timestamp] += _amount;

        periodToAmount[currPeriod] += _amount;
    }

    function popOne(address _theOwner) override public onlyGovernance returns(bool) {
        uint[] memory dateArr = dateArrMap[_theOwner];
        if(dateArr.length == 0) {
            return false;
        }
        uint startTime = block.timestamp - validTime;
        for(uint i = 0; i < dateArr.length; i++) {
            uint item = dateArr[i];
            if(item >= startTime) {
                if(amountMap[_theOwner][item] > 0) {
                    amountMap[_theOwner][item] -= 1;
                    if(amountMap[_theOwner][item] == 0) {
                        delete amountMap[_theOwner][item];
                    }
                    return true;
                }
            }
        }
        return false;
    }

    function getMyAmount(address _theOwner) override public view returns(uint) {
        uint[] memory dateArr = dateArrMap[_theOwner];
        uint startTime = block.timestamp - validTime;
        uint amount = 0;
        for(uint i = 0; i < dateArr.length; i++) {
            uint item = dateArr[i];
            if(item >= startTime) {
                if(amountMap[_theOwner][item] > 0) {
                    amount = amount + amountMap[_theOwner][item];
                }
            }
        }
        return amount;
    }

    function getAmountLeft() override public view returns(uint) {
        uint currPeriod = periodMana.getCurPeriod();
        uint totalAmount = periodMana.getAmountPerPeriod();
        uint usedAmount = periodToAmount[currPeriod];
        return (totalAmount - usedAmount);
    }

    function setCanvasPrice(uint _price) public onlyOwner {
        canvasPrice = _price;
    }

    function setValidTime(uint _validTime) public onlyOwner {
        validTime = _validTime;
    }

    function setCbd(address _cbd) public onlyOwner {
        cbd = IERC20(_cbd);
    }

}