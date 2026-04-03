// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployedDiamondState} from "@diamond-test/states/DeployedDiamondState.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {OwnableRolesLib} from "@diamond/libraries/OwnableRolesLib.sol";

/// @title OwnershipTester
/// @notice Extensive test coverage for ownership, handover ceremonies, and role management
contract OwnershipTester is DeployedDiamondState {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    uint256 constant ROLE_ADMIN = 1;
    uint256 constant ROLE_MINTER = 2;
    uint256 constant ROLE_BURNER = 4;

    function setUp() public override {
        super.setUp();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              CROWN — Ownership Transfer                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Owner is set correctly after deployment
    function testCrown_OwnerSetCorrectly() public view {
        assertEq(ownableRoles.owner(), diamondOwner);
    }

    /// @notice Transfer the crown to a new owner
    function testCrown_TransferOwnership() public {
        ownableRoles.transferOwnership(alice);
        assertEq(ownableRoles.owner(), alice);
    }

    /// @notice Ownership transfer emits the succession event
    function testCrown_TransferEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnableRolesLib.OwnershipTransferred(diamondOwner, alice);

        ownableRoles.transferOwnership(alice);
    }

    /// @notice Cannot transfer the crown to the zero address
    function testCrown_CannotTransferToZeroAddress() public {
        vm.expectRevert(OwnableRolesLib.NewOwnerIsZeroAddress.selector);
        ownableRoles.transferOwnership(address(0));
    }

    /// @notice Renouncing the crown leaves no owner
    function testCrown_RenounceOwnership() public {
        ownableRoles.renounceOwnership();
        assertEq(ownableRoles.owner(), address(0));
    }

    /// @notice Renounce emits transfer to zero address
    function testCrown_RenounceEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnableRolesLib.OwnershipTransferred(diamondOwner, address(0));

        ownableRoles.renounceOwnership();
    }

    /// @notice A commoner cannot claim the crown
    function testCrown_NonOwnerCannotTransfer() public {
        vm.prank(alice);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.transferOwnership(alice);
    }

    /// @notice A commoner cannot renounce what they don't own
    function testCrown_NonOwnerCannotRenounce() public {
        vm.prank(alice);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.renounceOwnership();
    }

    /// @notice After renouncing, owner-gated functions are locked
    function testCrown_NoOneCanActAfterRenounce() public {
        ownableRoles.renounceOwnership();

        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.transferOwnership(alice);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              HANDOVER — The Two-Step Succession Ceremony     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Requesting a handover sets the expiry 48 hours out
    function testHandover_RequestSetsExpiry() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        uint256 expiry = ownableRoles.ownershipHandoverExpiresAt(alice);
        assertEq(expiry, block.timestamp + 48 hours);
    }

    /// @notice Handover request emits an event
    function testHandover_RequestEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit OwnableRolesLib.OwnershipHandoverRequested(alice);

        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();
    }

    /// @notice Owner completes the handover — the crown passes
    function testHandover_CompleteTransfersOwnership() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        ownableRoles.completeOwnershipHandover(alice);
        assertEq(ownableRoles.owner(), alice);
    }

    /// @notice Completing a handover emits the transfer event
    function testHandover_CompleteEmitsTransferEvent() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.expectEmit(true, true, false, false);
        emit OwnableRolesLib.OwnershipTransferred(diamondOwner, alice);

        ownableRoles.completeOwnershipHandover(alice);
    }

    /// @notice Canceling a handover prevents completion
    function testHandover_CancelPreventsCompletion() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.prank(alice);
        ownableRoles.cancelOwnershipHandover();

        vm.expectRevert(OwnableRolesLib.NoHandoverRequest.selector);
        ownableRoles.completeOwnershipHandover(alice);
    }

    /// @notice Cancel emits event
    function testHandover_CancelEmitsEvent() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.expectEmit(true, false, false, false);
        emit OwnableRolesLib.OwnershipHandoverCanceled(alice);

        vm.prank(alice);
        ownableRoles.cancelOwnershipHandover();
    }

    /// @notice Handover expires after 48 hours — the window closes
    function testHandover_ExpiresAfter48Hours() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.warp(block.timestamp + 48 hours + 1);

        vm.expectRevert(OwnableRolesLib.NoHandoverRequest.selector);
        ownableRoles.completeOwnershipHandover(alice);
    }

    /// @notice Handover succeeds right at the 48-hour mark
    function testHandover_SucceedsAtExactExpiry() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.warp(block.timestamp + 48 hours);
        ownableRoles.completeOwnershipHandover(alice);
        assertEq(ownableRoles.owner(), alice);
    }

    /// @notice Cannot complete a handover that was never requested
    function testHandover_CannotCompleteNonExistent() public {
        vm.expectRevert(OwnableRolesLib.NoHandoverRequest.selector);
        ownableRoles.completeOwnershipHandover(alice);
    }

    /// @notice Non-owner cannot complete a handover
    function testHandover_NonOwnerCannotComplete() public {
        vm.prank(alice);
        ownableRoles.requestOwnershipHandover();

        vm.prank(bob);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.completeOwnershipHandover(alice);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              HALO — Roles Surrounding the Crown              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Granting roles updates the user's bitmap
    function testHalo_GrantRoles() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN | ROLE_MINTER);
        assertEq(ownableRoles.rolesOf(alice), ROLE_ADMIN | ROLE_MINTER);
    }

    /// @notice Granting roles emits the RolesUpdated event
    function testHalo_GrantEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnableRolesLib.RolesUpdated(alice, ROLE_ADMIN);

        ownableRoles.grantRoles(alice, ROLE_ADMIN);
    }

    /// @notice Granting a role twice is a no-op for that bit
    function testHalo_GrantTwiceIsIdempotent() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN);
        ownableRoles.grantRoles(alice, ROLE_ADMIN);
        assertEq(ownableRoles.rolesOf(alice), ROLE_ADMIN);
    }

    /// @notice Revoking roles clears specific bits
    function testHalo_RevokeRoles() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN | ROLE_MINTER | ROLE_BURNER);
        ownableRoles.revokeRoles(alice, ROLE_MINTER);
        assertEq(ownableRoles.rolesOf(alice), ROLE_ADMIN | ROLE_BURNER);
    }

    /// @notice Users can renounce their own roles
    function testHalo_RenounceRoles() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN | ROLE_MINTER);

        vm.prank(alice);
        ownableRoles.renounceRoles(ROLE_ADMIN);

        assertEq(ownableRoles.rolesOf(alice), ROLE_MINTER);
    }

    /// @notice hasAnyRole returns true if any bit matches
    function testHalo_HasAnyRole() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN);

        assertTrue(ownableRoles.hasAnyRole(alice, ROLE_ADMIN | ROLE_MINTER));
        assertFalse(ownableRoles.hasAnyRole(alice, ROLE_MINTER | ROLE_BURNER));
    }

    /// @notice hasAllRoles returns true only if all bits match
    function testHalo_HasAllRoles() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN | ROLE_MINTER);

        assertTrue(ownableRoles.hasAllRoles(alice, ROLE_ADMIN | ROLE_MINTER));
        assertTrue(ownableRoles.hasAllRoles(alice, ROLE_ADMIN));
        assertFalse(ownableRoles.hasAllRoles(alice, ROLE_ADMIN | ROLE_MINTER | ROLE_BURNER));
    }

    /// @notice Fresh address has no roles
    function testHalo_FreshAddressHasNoRoles() public view {
        assertEq(ownableRoles.rolesOf(bob), 0);
        assertFalse(ownableRoles.hasAnyRole(bob, type(uint256).max));
    }

    /// @notice Non-owner cannot grant roles
    function testHalo_NonOwnerCannotGrant() public {
        vm.prank(alice);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.grantRoles(bob, ROLE_ADMIN);
    }

    /// @notice Non-owner cannot revoke others' roles
    function testHalo_NonOwnerCannotRevoke() public {
        ownableRoles.grantRoles(alice, ROLE_ADMIN);

        vm.prank(bob);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        ownableRoles.revokeRoles(alice, ROLE_ADMIN);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              APPRAISAL — Role Utility Functions               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice rolesFromOrdinals converts index array to bitmap
    function testAppraisal_RolesFromOrdinals() public view {
        uint8[] memory ordinals = new uint8[](3);
        ordinals[0] = 0; // bit 0 = 1
        ordinals[1] = 1; // bit 1 = 2
        ordinals[2] = 2; // bit 2 = 4

        assertEq(ownableRoles.rolesFromOrdinals(ordinals), 7); // 1 | 2 | 4 = 7
    }

    /// @notice ordinalsFromRoles converts bitmap back to index array
    function testAppraisal_OrdinalsFromRoles() public view {
        uint8[] memory ordinals = ownableRoles.ordinalsFromRoles(7); // bits 0,1,2
        assertEq(ordinals.length, 3);
        assertEq(ordinals[0], 0);
        assertEq(ordinals[1], 1);
        assertEq(ordinals[2], 2);
    }

    /// @notice Roundtrip: ordinals → roles → ordinals preserves values
    function testAppraisal_RoundtripConversion() public view {
        uint8[] memory input = new uint8[](2);
        input[0] = 5;
        input[1] = 10;

        uint256 roles = ownableRoles.rolesFromOrdinals(input);
        uint8[] memory output = ownableRoles.ordinalsFromRoles(roles);

        assertEq(output.length, 2);
        assertEq(output[0], 5);
        assertEq(output[1], 10);
    }

    /// @notice Empty ordinals produces zero bitmap
    function testAppraisal_EmptyOrdinalsIsZero() public view {
        uint8[] memory empty = new uint8[](0);
        assertEq(ownableRoles.rolesFromOrdinals(empty), 0);
    }

    /// @notice Zero bitmap produces empty ordinals
    function testAppraisal_ZeroRolesIsEmptyOrdinals() public view {
        uint8[] memory ordinals = ownableRoles.ordinalsFromRoles(0);
        assertEq(ordinals.length, 0);
    }
}
