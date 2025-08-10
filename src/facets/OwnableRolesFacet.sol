// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";

/// @notice Simple single owner and multiroles authorization mixin.
/// @author David Dada
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/auth/OwnableRoles.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
contract OwnableRolesFacet {
    using LibOwnableRoles for *;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address _newOwner) public onlyOwner {
        _newOwner._transferOwnership();
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public onlyOwner {
        LibOwnableRoles._renounceOwnership();
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public {
        LibOwnableRoles._requestOwnershipHandover();
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public {
        LibOwnableRoles._cancelOwnershipHandover();
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address _pendingOwner) public onlyOwner {
        _pendingOwner._completeOwnershipHandover();
    }

    /// @dev Allows the owner to grant `user` `roles`.
    /// If the `user` already has a role, then it will be an no-op for the role.
    function grantRoles(address _user, uint256 _roles) public onlyOwner {
        _user._grantRoles(_roles);
    }

    /// @dev Allows the owner to remove `user` `roles`.
    /// If the `user` does not have a role, then it will be an no-op for the role.
    function revokeRoles(address _user, uint256 _roles) public onlyOwner {
        _user._removeRoles(_roles);
    }

    /// @dev Allow the caller to remove their own roles.
    /// If the caller does not have a role, then it will be an no-op for the role.
    function renounceRoles(uint256 _roles) public {
        msg.sender._removeRoles(_roles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view returns (address result_) {
        result_ = LibOwnableRoles._owner();
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address _pendingOwner) public view returns (uint256 result_) {
        result_ = _pendingOwner._ownershipHandoverExpiresAt();
    }

    /// @dev Returns the roles of `user`.
    function rolesOf(address _user) public view returns (uint256 roles_) {
        roles_ = _user._rolesOf();
    }

    /// @dev Returns whether `user` has any of `roles`.
    function hasAnyRole(address _user, uint256 _roles) public view returns (bool) {
        return _user._rolesOf() & _roles != 0;
    }

    /// @dev Returns whether `user` has all of `roles`.
    function hasAllRoles(address _user, uint256 _roles) public view returns (bool) {
        return _user._rolesOf() & _roles == _roles;
    }

    /// @dev Convenience function to return a `roles` bitmap from an array of `ordinals`.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function rolesFromOrdinals(uint8[] memory ordinals) external pure returns (uint256 roles_) {
        roles_ = ordinals._rolesFromOrdinals();
    }

    /// @dev Convenience function to return an array of `ordinals` from the `roles` bitmap.
    /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
    /// Not recommended to be called on-chain.
    function ordinalsFromRoles(uint256 roles) external pure returns (uint8[] memory ordinals_) {
        ordinals_ = roles._ordinalsFromRoles();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev This override returns true to make `_initializeOwner` prevent double-initialization.
    function _guardInitializeOwner() internal pure returns (bool guard) {
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() {
        LibOwnableRoles._checkOwner();
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles`.
    modifier onlyRoles(uint256 _roles) {
        LibOwnableRoles._checkRoles(_roles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account
    ///      with `roles`. Checks for ownership first, then lazily checks for roles.
    modifier onlyOwnerOrRoles(uint256 _roles) {
        LibOwnableRoles._checkOwnerOrRoles(_roles);
        _;
    }

    /// @dev Marks a function as only callable by an account with `roles` or the owner.
    /// Checks for roles first, then lazily checks for ownership.
    modifier onlyRolesOrOwner(uint256 _roles) {
        LibOwnableRoles._checkRolesOrOwner(_roles);
        _;
    }
}
