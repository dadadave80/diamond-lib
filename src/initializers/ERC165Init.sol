// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Lib} from "@diamond/libraries/ERC165Lib.sol";

/// @title ERC165Init
/// @notice Provides an initializer to register ERC165 interface support
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
contract ERC165Init {
    /// @notice Initialize ERC165 interface registration
    /// @dev Registers support for the ERC165 interface
    function init() public {
        ERC165Lib.registerInterface();
    }
}
