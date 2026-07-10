// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFacet} from "@diamond/interfaces/IFacet.sol";

contract MockFacetA is IFacet {
    function funcA1() external pure returns (uint256) {
        return 1;
    }

    function funcA2() external pure returns (uint256) {
        return 2;
    }

    function funcA3() external pure returns (uint256) {
        return 3;
    }

    /// @inheritdoc IFacet
    function exportSelectors() external pure returns (bytes memory selectors_) {
        selectors_ = abi.encodePacked(this.funcA1.selector, this.funcA2.selector, this.funcA3.selector);
    }
}
