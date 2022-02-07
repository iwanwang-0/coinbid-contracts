// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Governance is Ownable {

    mapping(address => bool) private governanceMap;
    event AddGovernance(address newGovernance);
    event RemoveGovernance(address oldGovernance);

    constructor() {
        address msgSender = _msgSender();

        governanceMap[msgSender] = true;
        emit AddGovernance(msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(governanceMap[_msgSender()], "Governance: caller is not the Governance");
        _;
    }

    function addGovernance(address _newGovernance) public virtual onlyOwner {
        governanceMap[_newGovernance] = true;
        emit AddGovernance(_newGovernance);
    }

    function removeGovernance(address _oldGovernance) public virtual onlyOwner {
        governanceMap[_oldGovernance] = false;
        emit RemoveGovernance(_oldGovernance);
    }

    function isGovernance(address _governance) public virtual view returns(bool) {
        return governanceMap[_governance];
    }
}