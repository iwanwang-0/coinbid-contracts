// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library UintArray {

    // Delete the element at the specified index.
    // This will disrupt the order of the array.
    // It will returns the the array's length.
    function unsafeDelete(uint[] storage self, uint16 index) public returns(bool, uint16) {
        require(index < self.length, "UintArray: Index is out of range.");
        bool isChanged = false;
        if(index == self.length - 1) {
            self.pop();
        } else {
            self[index] = self[self.length -1];
            self.pop();
            isChanged = true;
        }

        return (isChanged, index);
    }
}