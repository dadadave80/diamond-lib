// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";

/// @title OwnableInit
/// @notice Provides an initializer to set the contract owner
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Intended to be called as a standalone initializer via diamond cut or through MultiInit
contract OwnableInit {
    /// @notice Initialize the contract owner.
    /// @dev This function is called during the diamond cut process to set up the owner.
    /// @param _owner The address to set as the contract owner.
    function initOwner(address _owner) public {
        OwnableLib.initializeOwner(_owner);
    }
}
