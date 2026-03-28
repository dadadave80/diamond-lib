// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib} from "@diamond/libraries/DiamondLib.sol";

/// @notice Thrown when the length of the address array does not match the length of the calldata array.
/// @dev Used in initializer logic to ensure one-to-one mapping between addresses and initialization calldata.
error AddressAndCalldataLengthMismatch();

contract MultiInit {
    function multiInit(address[] calldata _initAddresses, bytes[] calldata _initData) public {
        uint256 initAddressesLength = _initAddresses.length;
        if (initAddressesLength != _initData.length) {
            revert AddressAndCalldataLengthMismatch();
        }

        for (uint256 i; i < initAddressesLength; ++i) {
            DiamondLib.initializeDiamondCut(_initAddresses[i], _initData[i]);
        }
    }
}
