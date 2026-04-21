// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib} from "@diamond/libraries/DiamondLib.sol";

/// @title DiamondInit
/// @notice Provides an initializer to set up the Diamond with ERC-165 support
contract DiamondInit {
    function init() public {
        DiamondLib.registerInterface();
    }
}
