// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockRevertInit {
    error CustomInitError();

    function initWithError() external pure {
        revert CustomInitError();
    }

    function initNoData() external pure {
        assembly ("memory-safe") {
            revert(0, 0)
        }
    }
}
