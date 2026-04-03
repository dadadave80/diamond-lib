// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockFacetB {
    /// @dev Same signature as MockFacetA.funcA1 — same selector, different return value.
    function funcA1() external pure returns (uint256) {
        return 100;
    }

    function funcB1() external pure returns (uint256) {
        return 200;
    }
}
