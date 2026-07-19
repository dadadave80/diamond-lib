// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InitializableLib} from "@diamond-test/utils/InitializableLib.sol";

/// @notice Initializable mixin for upgradeable contracts.
/// @dev All logic lives in {InitializableLib}; this contract only exposes it
/// as modifiers and internal functions for inheritors.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Initializable.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy/utils/Initializable.sol)
abstract contract Initializable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override to return a non-zero custom storage slot if required.
    function _initializableSlot() internal pure virtual returns (bytes32) {
        return InitializableLib.initializableSlot();
    }

    /// @dev Guards an initializer function so that it can be invoked at most once.
    ///
    /// You can guard a function with `onlyInitializing` such that it can be called
    /// through a function guarded with `initializer`.
    ///
    /// This is similar to `reinitializer(1)`, except that in the context of a constructor,
    /// an `initializer` guarded function can be invoked multiple times.
    /// This can be useful during testing and is not expected to be used in production.
    ///
    /// Emits an {Initialized} event.
    modifier initializer() {
        bytes32 s = InitializableLib.preInitializer(_initializableSlot());
        _;
        InitializableLib.postInitializer(s);
    }

    /// @dev Guards a reinitializer function so that it can be invoked at most once.
    ///
    /// You can guard a function with `onlyInitializing` such that it can be called
    /// through a function guarded with `reinitializer`.
    ///
    /// Emits an {Initialized} event.
    modifier reinitializer(uint64 _version) {
        bytes32 s = _initializableSlot();
        InitializableLib.preReinitializer(s, _version);
        _;
        InitializableLib.postReinitializer(s, _version);
    }

    /// @dev Guards a function such that it can only be called in the scope
    /// of a function guarded with `initializer` or `reinitializer`.
    modifier onlyInitializing() {
        InitializableLib.checkInitializing(_initializableSlot());
        _;
    }

    /// @dev Locks any future initializations by setting the initialized version to `2**64 - 1`.
    ///
    /// Calling this in the constructor will prevent the contract from being initialized
    /// or reinitialized. It is recommended to use this to lock implementation contracts
    /// that are designed to be called through proxies.
    ///
    /// Emits an {Initialized} event the first time it is successfully called.
    function _disableInitializers() internal virtual {
        InitializableLib.disableInitializers(_initializableSlot());
    }

    /// @dev Returns the highest version that has been initialized.
    function _getInitializedVersion() internal view virtual returns (uint64) {
        return InitializableLib.getInitializedVersion(_initializableSlot());
    }

    /// @dev Returns whether the contract is currently initializing.
    function _isInitializing() internal view virtual returns (bool) {
        return InitializableLib.isInitializing(_initializableSlot());
    }
}
