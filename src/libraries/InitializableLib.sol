// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       CUSTOM ERRORS                        */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev The contract is already initialized.
error InvalidInitialization();

/// @dev The contract is not initializing.
error NotInitializing();

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                           EVENTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev Triggered when the contract has been initialized.
event Initialized(uint64 version);

/// @dev `keccak256(bytes("Initialized(uint64)"))`.
bytes32 constant _INITIALIZED_EVENT_SIGNATURE = 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2;

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STORAGE                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev The default initializable slot is given by:
/// `bytes32(~uint256(uint32(bytes4(keccak256("_INITIALIZABLE_SLOT")))))`.
///
/// Bits Layout:
/// - [0]     `initializing`
/// - [1..64] `initializedVersion`
bytes32 constant _INITIALIZABLE_SLOT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf601132;

/// @notice Initializable mixin for the upgradeable contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Initializable.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy/utils/Initializable.sol)
library InitializableLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override to return a non-zero custom storage slot if required.
    function initializableSlot() internal pure returns (bytes32) {
        return _INITIALIZABLE_SLOT;
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
        bytes32 s = initializableSlot();
        preInitializer(s);
        _;
        postInitializer(s);
    }

    function preInitializer(bytes32 _initializableSlot) internal {
        assembly ("memory-safe") {
            let i := sload(_initializableSlot)
            // Set `initializing` to 1, `initializedVersion` to 1.
            sstore(_initializableSlot, 3)
            // If `!(initializing == 0 && initializedVersion == 0)`.
            if i {
                // If `!(address(this).code.length == 0 && initializedVersion == 1)`.
                if iszero(lt(extcodesize(address()), eq(shr(1, i), 1))) {
                    mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                    revert(0x1c, 0x04)
                }
                _initializableSlot := shl(shl(255, i), _initializableSlot) // Skip initializing if `initializing == 1`.
            }
        }
    }

    function postInitializer(bytes32 _initializableSlot) internal {
        assembly ("memory-safe") {
            if _initializableSlot {
                // Set `initializing` to 0, `initializedVersion` to 1.
                sstore(_initializableSlot, 2)
                // Emit the {Initialized} event.
                mstore(0x20, 1)
                log1(0x20, 0x20, _INITIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    /// @dev Guards a reinitializer function so that it can be invoked at most once.
    ///
    /// You can guard a function with `onlyInitializing` such that it can be called
    /// through a function guarded with `reinitializer`.
    ///
    /// Emits an {Initialized} event.
    modifier reinitializer(uint64 _version) {
        bytes32 s = initializableSlot();
        preReinitializer(s, _version);
        _;
        postReinitializer(s, _version);
    }

    function preReinitializer(bytes32 _initializableSlot, uint64 _version) internal {
        assembly ("memory-safe") {
            // Clean upper bits, and shift left by 1 to make space for the initializing bit.
            _version := shl(1, and(_version, 0xffffffffffffffff))
            let i := sload(_initializableSlot)
            // If `initializing == 1 || initializedVersion >= version`.
            if iszero(lt(and(i, 1), lt(i, _version))) {
                mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                revert(0x1c, 0x04)
            }
            // Set `initializing` to 1, `initializedVersion` to `version`.
            sstore(_initializableSlot, or(1, _version))
        }
    }

    function postReinitializer(bytes32 _initializableSlot, uint64 _version) internal {
        assembly ("memory-safe") {
            // Clean upper bits, and shift left by 1 to match storage layout.
            _version := shl(1, and(_version, 0xffffffffffffffff))
            // Set `initializing` to 0, `initializedVersion` to `version`.
            sstore(_initializableSlot, _version)
            // Emit the {Initialized} event.
            mstore(0x20, shr(1, _version))
            log1(0x20, 0x20, _INITIALIZED_EVENT_SIGNATURE)
        }
    }

    /// @dev Guards a function such that it can only be called in the scope
    /// of a function guarded with `initializer` or `reinitializer`.
    modifier onlyInitializing() {
        checkInitializing(initializableSlot());
        _;
    }

    /// @dev Reverts if the contract is not initializing.
    function checkInitializing(bytes32 _initializableSlot) internal view {
        assembly ("memory-safe") {
            if iszero(and(1, sload(_initializableSlot))) {
                mstore(0x00, 0xd7e6bcf8) // `NotInitializing()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Locks any future initializations by setting the initialized version to `2**64 - 1`.
    ///
    /// Calling this in the constructor will prevent the contract from being initialized
    /// or reinitialized. It is recommended to use this to lock implementation contracts
    /// that are designed to be called through proxies.
    ///
    /// Emits an {Initialized} event the first time it is successfully called.
    function disableInitializers(bytes32 _initializableSlot) internal {
        assembly ("memory-safe") {
            let i := sload(_initializableSlot)
            if and(i, 1) {
                mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                revert(0x1c, 0x04)
            }
            let uint64max := 0xffffffffffffffff
            if iszero(eq(shr(1, i), uint64max)) {
                // Set `initializing` to 0, `initializedVersion` to `2**64 - 1`.
                sstore(_initializableSlot, shl(1, uint64max))
                // Emit the {Initialized} event.
                mstore(0x20, uint64max)
                log1(0x20, 0x20, _INITIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    /// @dev Returns the highest version that has been initialized.
    function getInitializedVersion(bytes32 _initializableSlot) internal view returns (uint64 version_) {
        assembly ("memory-safe") {
            version_ := shr(1, sload(_initializableSlot))
        }
    }

    /// @dev Returns whether the contract is currently initializing.
    function isInitializing(bytes32 _initializableSlot) internal view returns (bool result_) {
        assembly ("memory-safe") {
            result_ := and(1, sload(_initializableSlot))
        }
    }
}
