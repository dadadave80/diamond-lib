// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC165Lib
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @notice Library for checking ERC165 interface support
library ERC165Lib {
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return supported_ `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceId) internal pure returns (bool supported_) {
        assembly ("memory-safe") {
            // ERC165 interface IDs are 4 bytes, so we can shift right by 224 bits to get the first byte
            switch shr(224, _interfaceId)
            /// @dev type(ERC165).interfaceId
            case 0x01ffc9a7 {
                supported_ := true
            }
            /// @dev type(IERC173).interfaceId
            case 0x7f5828d0 {
                supported_ := true
            }
            /// @dev type(IDiamondCut).interfaceId
            case 0x1f931c1c {
                supported_ := true
            }
            /// @dev type(IDiamondLoupe).interfaceId
            case 0x48e2b093 {
                supported_ := true
            }
            /// @dev Invalid interface ID (ERC165 specifies that 0xffffffff is not a valid interface ID and must return false)
            case 0xffffffff {
                supported_ := false
            }
            /// @dev Invalid interface ID
            default {
                supported_ := false
            }
        }
    }
}
