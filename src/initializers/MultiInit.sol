// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Thrown when the length of the address array does not match the length of the calldata array.
/// @dev Used in initializer logic to ensure one-to-one mapping between addresses and initialization calldata.
error AddressAndCalldataLengthMismatch();
/// @notice The initializer at the zero-based step index has no bytecode.
error NoBytecodeAtAddress(uint256 index, address initAddress);
/// @notice The zero-based step index contains a zero initializer; the whole batch is reverted.
error MultiInit__ZeroInit(uint256 index);
/// @notice The delegatecall at the zero-based step index failed; `reason` preserves its original revert bytes.
error MultiInit__StepFailed(uint256 index, address init, bytes reason);

/// @title MultiInit
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @notice Provides a utility function to perform multiple delegatecall initializations in a single transaction,
///         with indexed error reporting and atomic validation. Zero entries are invalid, not sentinels.
contract MultiInit {
    function multiInit(address[] calldata _initAddresses, bytes[] calldata _initData) public {
        uint256 initAddressesLength = _initAddresses.length;
        if (initAddressesLength != _initData.length) {
            revert AddressAndCalldataLengthMismatch();
        }

        for (uint256 i; i < initAddressesLength; ++i) {
            address initAddress = _initAddresses[i];
            if (initAddress == address(0)) revert MultiInit__ZeroInit(i);
            if (initAddress.code.length == 0) revert NoBytecodeAtAddress(i, initAddress);
            (bool success, bytes memory err) = initAddress.delegatecall(_initData[i]);
            if (!success) {
                revert MultiInit__StepFailed(i, initAddress, err);
            }
        }
    }
}
