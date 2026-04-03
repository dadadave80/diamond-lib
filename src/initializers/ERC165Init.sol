// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib, DiamondStorage} from "@diamond/libraries/DiamondLib.sol";

/// @title ERC165Init
/// @notice Provides an initializer to register standard diamond interface support (ERC-165, ERC-173, IDiamondCut, IDiamondLoupe)
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Intended to be called as a standalone initializer via diamond cut or through MultiInit
contract ERC165Init {
    /// @notice Register standard diamond ERC-165 interface IDs.
    /// @dev Sets support for ERC-165, ERC-173, IDiamondCut, and IDiamondLoupe.
    function initERC165() public {
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
