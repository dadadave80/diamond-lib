// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib, DiamondStorage} from "@diamond/libraries/DiamondLib.sol";
import {OwnableRolesLib} from "@diamond/libraries/OwnableRolesLib.sol";

/// @title DiamondInit
/// @notice Provides an initializer to register standard interface support (ERC-165, ERC-173, IDiamondCut, IDiamondLoupe)
/// @author Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol)
/// @author Modified by David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Intended to be called as the `initDiamond` function in a diamond cut to set up ERC-165 interface IDs
contract DiamondInit {
    /// @notice Initialize the contract with the ERC165 interface support.
    /// @dev This function is called during the diamond cut process to set up
    ///      the initial state of the contract.
    function initDiamond(address _owner) public {
        // Initialize the owner
        OwnableRolesLib._initializeOwner(_owner);

        DiamondStorage storage ds = DiamondLib.diamondStorage();
        /// @dev type(ERC165).interfaceId
        ds.supportedInterfaces[0x01ffc9a7] = true;
        /// @dev type(IERC173).interfaceId
        ds.supportedInterfaces[0x7f5828d0] = true;
        /// @dev type(IDiamondCut).interfaceId
        ds.supportedInterfaces[0x1f931c1c] = true;
        /// @dev type(IDiamondLoupe).interfaceId
        ds.supportedInterfaces[0x48e2b093] = true;
    }
}
