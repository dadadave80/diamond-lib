// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployedDiamondState} from "@diamond-test/states/DeployedDiamondState.sol";
// import {OwnableFacet} from "@diamond/facets/OwnableFacet.sol";
import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";

/// @title OwnershipTester
/// @notice Extensive test coverage for ownership, handover ceremonies, and role management
contract OwnershipTester is DeployedDiamondState {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

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
        assertEq(ownable.owner(), diamondOwner);
    }

    /// @notice Transfer the crown to a new owner
    function testCrown_TransferOwnership() public {
        ownable.transferOwnership(alice);
        assertEq(ownable.owner(), alice);
    }

    /// @notice Ownership transfer emits the succession event
    function testCrown_TransferEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnableLib.OwnershipTransferred(diamondOwner, alice);

        ownable.transferOwnership(alice);
    }

    /// @notice Cannot transfer the crown to the zero address
    function testCrown_CannotTransferToZeroAddress() public {
        vm.expectRevert(OwnableLib.NewOwnerIsZeroAddress.selector);
        ownable.transferOwnership(address(0));
    }

    /// @notice Renouncing the crown leaves no owner
    function testCrown_RenounceOwnership() public {
        ownable.renounceOwnership();
        assertEq(ownable.owner(), address(0));
    }

    /// @notice Renounce emits transfer to zero address
    function testCrown_RenounceEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnableLib.OwnershipTransferred(diamondOwner, address(0));

        ownable.renounceOwnership();
    }

    /// @notice A commoner cannot claim the crown
    function testCrown_NonOwnerCannotTransfer() public {
        vm.prank(alice);
        vm.expectRevert(OwnableLib.Unauthorized.selector);
        ownable.transferOwnership(alice);
    }

    /// @notice A commoner cannot renounce what they don't own
    function testCrown_NonOwnerCannotRenounce() public {
        vm.prank(alice);
        vm.expectRevert(OwnableLib.Unauthorized.selector);
        ownable.renounceOwnership();
    }

    /// @notice After renouncing, owner-gated functions are locked
    function testCrown_NoOneCanActAfterRenounce() public {
        ownable.renounceOwnership();

        vm.expectRevert(OwnableLib.Unauthorized.selector);
        ownable.transferOwnership(alice);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              HANDOVER — The Two-Step Succession Ceremony     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Requesting a handover sets the expiry 48 hours out
    function testHandover_RequestSetsExpiry() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        uint256 expiry = ownable.ownershipHandoverExpiresAt(alice);
        assertEq(expiry, block.timestamp + 48 hours);
    }

    /// @notice Handover request emits an event
    function testHandover_RequestEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit OwnableLib.OwnershipHandoverRequested(alice);

        vm.prank(alice);
        ownable.requestOwnershipHandover();
    }

    /// @notice Owner completes the handover — the crown passes
    function testHandover_CompleteTransfersOwnership() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        ownable.completeOwnershipHandover(alice);
        assertEq(ownable.owner(), alice);
    }

    /// @notice Completing a handover emits the transfer event
    function testHandover_CompleteEmitsTransferEvent() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.expectEmit(true, true, false, false);
        emit OwnableLib.OwnershipTransferred(diamondOwner, alice);

        ownable.completeOwnershipHandover(alice);
    }

    /// @notice Canceling a handover prevents completion
    function testHandover_CancelPreventsCompletion() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.prank(alice);
        ownable.cancelOwnershipHandover();

        vm.expectRevert(OwnableLib.NoHandoverRequest.selector);
        ownable.completeOwnershipHandover(alice);
    }

    /// @notice Cancel emits event
    function testHandover_CancelEmitsEvent() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.expectEmit(true, false, false, false);
        emit OwnableLib.OwnershipHandoverCanceled(alice);

        vm.prank(alice);
        ownable.cancelOwnershipHandover();
    }

    /// @notice Handover expires after 48 hours — the window closes
    function testHandover_ExpiresAfter48Hours() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.warp(block.timestamp + 48 hours + 1);

        vm.expectRevert(OwnableLib.NoHandoverRequest.selector);
        ownable.completeOwnershipHandover(alice);
    }

    /// @notice Handover succeeds right at the 48-hour mark
    function testHandover_SucceedsAtExactExpiry() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.warp(block.timestamp + 48 hours);
        ownable.completeOwnershipHandover(alice);
        assertEq(ownable.owner(), alice);
    }

    /// @notice Cannot complete a handover that was never requested
    function testHandover_CannotCompleteNonExistent() public {
        vm.expectRevert(OwnableLib.NoHandoverRequest.selector);
        ownable.completeOwnershipHandover(alice);
    }

    /// @notice Non-owner cannot complete a handover
    function testHandover_NonOwnerCannotComplete() public {
        vm.prank(alice);
        ownable.requestOwnershipHandover();

        vm.prank(bob);
        vm.expectRevert(OwnableLib.Unauthorized.selector);
        ownable.completeOwnershipHandover(alice);
    }
}
