// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Thrown when the length of the address array does not match the length of the calldata array.
/// @dev Used in initializer logic to ensure one-to-one mapping between addresses and initialization calldata.
error AddressAndCalldataLengthMismatch();
error NoBytecodeAtAddress(address initAddress);
error InitializeReverted(address initAddress, bytes initCalldata);

/// @title MultiInit
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @notice Provides a utility function to perform multiple delegatecall initializations in a single transaction,
///         with robust error handling and validation.
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
                        let returndataSize := mload(err)
                        revert(add(32, err), returndataSize)
                    }
                } else {
                    revert InitializeReverted(initAddress, _initData[i]);
                }
            }
        }
    }
}
