// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib} from "@diamond/libraries/DiamondLib.sol";
import {ERC165Lib} from "@diamond/libraries/ERC165Lib.sol";
import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";

/// @title DiamondInit
/// @notice Provides an initializer to set up the Diamond with ERC-165 support
///         and ownership management
contract DiamondInit {
    /// @dev This function is called during the diamond cut process to set up the owner.
    /// @param _owner The address to set as the contract owner.
    function init(address _owner) public {
        OwnableLib.initializeOwner(_owner);
        ERC165Lib.registerInterface();
        OwnableLib.registerInterface();
        DiamondLib.registerInterface();
    }
}
