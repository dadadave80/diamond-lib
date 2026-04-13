// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Lib} from "@diamond/libraries/ERC165Lib.sol";

/// @title ERC165Facet
/// @notice Diamond facet that implements the ERC-165 standard interface detection
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @dev Delegates to ERC165Lib which hardcodes support for ERC-165, ERC-173, IDiamondCut, and IDiamondLoupe
contract ERC165Facet {
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId` and
    ///  `_interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return ERC165Lib.supportsInterface(_interfaceId);
    }
}
