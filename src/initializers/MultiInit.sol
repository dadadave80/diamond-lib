// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Thrown when the length of the address array does not match the length of the calldata array.
/// @dev Used in initializer logic to ensure one-to-one mapping between addresses and initialization calldata.
error AddressAndCalldataLengthMismatch();
error NoBytecodeAtAddress(address initAddress);
error InitializeReverted(address initAddress, bytes initCalldata);

contract MultiInit {
    function multiInit(address[] calldata _initAddresses, bytes[] calldata _initData) public {
        uint256 initAddressesLength = _initAddresses.length;
        if (initAddressesLength != _initData.length) {
            revert AddressAndCalldataLengthMismatch();
        }

        for (uint256 i; i < initAddressesLength; ++i) {
            address initAddress = _initAddresses[i];
            if (initAddress == address(0)) return;
            if (initAddress.code.length == 0) revert NoBytecodeAtAddress(initAddress);
            (bool success, bytes memory err) = initAddress.delegatecall(_initData[i]);
            if (!success) {
                if (err.length > 0) {
                    // bubble up error
                    assembly ("memory-safe") {
                        let returndata_size := mload(err)
                        revert(add(32, err), returndata_size)
                    }
                } else {
                    revert InitializeReverted(initAddress, _initData[i]);
                }
            }
        }
    }
}
