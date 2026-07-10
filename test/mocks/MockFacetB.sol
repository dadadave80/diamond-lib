// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFacet} from "@diamond/interfaces/IFacet.sol";

contract MockFacetB is IFacet {
    /// @dev Same signature as MockFacetA.funcA1 — same selector, different return value.
    function funcA1() external pure returns (uint256) {
        return 100;
    }

    function funcB1() external pure returns (uint256) {
        return 200;
    }

    /// @inheritdoc IFacet
    function exportSelectors() external pure returns (bytes memory selectors_) {
        selectors_ = abi.encodePacked(this.funcA1.selector, this.funcB1.selector);
    }
}
