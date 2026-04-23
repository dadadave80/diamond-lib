// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//*//////////////////////////////////////////////////////////////////////////
//                                  STORAGE
//////////////////////////////////////////////////////////////////////////*//

/// @dev `keccak256(abi.encode(uint256(keccak256("diamond.lib.storage.ERC165")) - 1)) & ~bytes32(uint256(0xff))`.
bytes32 constant ERC165_STORAGE_LOCATION = 0x9ca7f3e2e2bfb15fdf072b85dde92837cddacee6cf2f6b38cd06c9457c1c4200;

/// @dev 0x01ffc9a7 is `type(IERC165).interfaceId`.
/// `keccak256(abi.encode(bytes4(0x01ffc9a7), 0x9ca7f3e2e2bfb15fdf072b85dde92837cddacee6cf2f6b38cd06c9457c1c4200))`.
bytes32 constant _ERC165_MAP_IERC165_SLOT = 0x124f8c425b7daf42b5736cba92e48ad5cb80b5f2f886a1fb5b276b3154f069f4;

/// @notice Struct for storing ERC165 interface support information
/// @dev Implements ERC-165 storage layout for tracking supported interface IDs
/// @custom:storage-location erc7201:diamond.lib.storage.ERC165
struct ERC165Storage {
    mapping(bytes4 interfaceId => bool) supportedInterfaces;
}

/// @title ERC165Lib
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @notice Library for checking ERC165 interface support
library ERC165Lib {
    /// @notice Get the ERC165 storage pointer
    /// @return es_ Reference to the ERC165 storage struct
    /// @dev Returns a reference to the ERC165 storage struct located at slot 0x9ca7f3e2e2bfb15fdf072b85dde92837cddacee6cf2f6b38cd06c9457c1c4200
    function erc165Storage() internal pure returns (ERC165Storage storage es_) {
        assembly {
            // Set the storage struct's slot to the ERC165_STORAGE_LOCATION constant
            // This allows the mapping inside ERC165Storage to be accessed via es_.supportedInterfaces
            es_.slot := ERC165_STORAGE_LOCATION
        }
    }

    /// @notice Registers support for the ERC165 interface and other standard interfaces
    /// @dev Marks this library as implementing ERC165 interface by setting the appropriate flag in storage.
    ///  Must be called before using supportsInterface().
    /// Stores directly to _ERC165_MAP_IERC165_SLOT to indicate ERC165 support.
    function registerInterface() internal {
        assembly ("memory-safe") {
            sstore(_ERC165_MAP_IERC165_SLOT, true)
        }
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165 (bytes4)
    /// @return supported_ `true` if the contract implements `interfaceID`, `false` otherwise
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// Computes storage location: keccak256(abi.encode(_interfaceId, ERC165_STORAGE_LOCATION))
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool supported_) {
        assembly ("memory-safe") {
            // Compute the storage key for this interface in the mapping:
            // keccak256(abi.encode(_interfaceId, ERC165_STORAGE_LOCATION))

            // Store _interfaceId at memory offset 0x00
            mstore(0x00, _interfaceId)

            // Store ERC165_STORAGE_LOCATION at memory offset 0x20
            mstore(0x20, ERC165_STORAGE_LOCATION)

            // Hash the packed encoding (0x00:0x40 = 64 bytes)
            // This is the storage key for the mapping entry
            // Load the value from that key
            supported_ := sload(keccak256(0x00, 0x40))
        }
    }
}
