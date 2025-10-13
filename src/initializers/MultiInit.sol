// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {AddressAndCalldataLengthMismatch} from "@diamond/libraries/errors/DiamondErrors.sol";

contract MultiInit {
    function multiInit(address[] memory _initAddresses, bytes[] memory _initData) public {
        uint256 initAddressesLength = _initAddresses.length;
        if (initAddressesLength != _initData.length) revert AddressAndCalldataLengthMismatch();

        for (uint256 i; i < initAddressesLength; ++i) {
            LibDiamond._initializeDiamondCut(_initAddresses[i], _initData[i]);
        }
    }
}
