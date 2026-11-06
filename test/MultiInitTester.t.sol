// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockDiamond} from "@diamond-test/mocks/MockDiamond.sol";
import {DeployedDiamondState} from "@diamond-test/states/DeployedDiamondState.sol";
import {InitializableLib} from "@diamond-test/utils/InitializableLib.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {FacetCut, FacetCutAction, FunctionDoesNotExist} from "@diamond/libraries/DiamondLib.sol";

/// @dev Independent expected ABI lets these regressions run against the old implementation for red proof.
interface ExpectedMultiInitErrors {
    error MultiInit__StepFailed(uint256 index, address init, bytes reason);
    error MultiInit__ZeroInit(uint256 index);
    error NoBytecodeAtAddress(uint256 index, address initAddress);
    error AddressAndCalldataLengthMismatch();
}

/// @dev Original test fixture: ordered writes and representative revert payloads in the diamond's context.
contract MultiInitExecutionFixture {
    // keccak256("diamond-lib.test.MultiInit.value"). This slot is used only by the regression fixture.
    bytes32 internal constant VALUE_SLOT = 0x5287c46cd261b27edaf5bfa1679da048ba42988a2e1de7535bebd22bfce41575;

    error StepError(uint256 value);

    function append(uint256 digit) external {
        assembly ("memory-safe") {
            sstore(VALUE_SLOT, add(mul(sload(VALUE_SLOT), 10), digit))
        }
    }

    function value() external view returns (uint256 result) {
        assembly ("memory-safe") {
            result := sload(VALUE_SLOT)
        }
    }

    function failCustom(uint256 value_) external pure {
        revert StepError(value_);
    }

    function failString() external pure {
        revert("middle step failed");
    }

    function failPanic() external pure {
        assert(false);
    }

    function failEmpty() external pure {
        assembly ("memory-safe") {
            revert(0, 0)
        }
    }
}

contract MultiInitTester is DeployedDiamondState {
    bytes32 constant VALUE_SLOT = 0x5287c46cd261b27edaf5bfa1679da048ba42988a2e1de7535bebd22bfce41575;
    MultiInit multi;
    MultiInitExecutionFixture step;

    function setUp() public override {
        super.setUp();
        multi = new MultiInit();
        step = new MultiInitExecutionFixture();
    }

    function _cuts() private view returns (FacetCut[] memory cuts) {
        cuts = new FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = step.value.selector;
        cuts[0] = FacetCut(address(step), FacetCutAction.Add, selectors);
    }

    function _steps() private view returns (address[] memory addresses, bytes[] memory data) {
        addresses = new address[](3);
        data = new bytes[](3);
        for (uint256 i; i < 3; ++i) {
            addresses[i] = address(step);
            data[i] = abi.encodeCall(step.append, (i + 1));
        }
    }

    function _cut(address[] memory addresses, bytes[] memory data) private returns (bool ok, bytes memory result) {
        return diamond.call(
            abi.encodeCall(
                IDiamondCut.diamondCut,
                (_cuts(), address(multi), abi.encodeCall(MultiInit.multiInit, (addresses, data)))
            )
        );
    }

    function _args(bytes memory result) private pure returns (bytes memory args) {
        require(result.length >= 4, "missing error selector");
        args = new bytes(result.length - 4);
        for (uint256 i; i < args.length; ++i) {
            args[i] = result[i + 4];
        }
    }

    function _assertRollback() private view {
        assertEq(vm.load(diamond, VALUE_SLOT), bytes32(0), "earlier initialization writes rolled back");
        assertEq(diamondLoupe.facetAddress(step.value.selector), address(0), "enclosing cut rolled back");
    }

    function _assertMiddleFailure(bytes memory failingCall, bytes memory innerReason) private {
        (address[] memory addresses, bytes[] memory data) = _steps();
        data[1] = failingCall;
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertFalse(ok, "middle failure must revert the entire cut");
        assertEq(bytes4(result), ExpectedMultiInitErrors.MultiInit__StepFailed.selector);
        (uint256 index, address failedInit, bytes memory reason) = abi.decode(_args(result), (uint256, address, bytes));
        assertEq(index, 1);
        assertEq(failedInit, address(step));
        assertEq(reason, innerReason, "inner revert bytes preserved exactly");
        _assertRollback();
    }

    function test_OrderedSuccessWritesDiamondState() public {
        (address[] memory addresses, bytes[] memory data) = _steps();
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertTrue(ok, string(result));
        assertEq(MultiInitExecutionFixture(diamond).value(), 123, "every step ran in order");
        assertEq(step.value(), 0, "initializer state is in the diamond");
    }

    function test_EmptyBatchIsAnExplicitNoop() public {
        multi.multiInit(new address[](0), new bytes[](0));
    }

    function test_LengthMismatchRetainsItsError() public {
        vm.expectRevert(ExpectedMultiInitErrors.AddressAndCalldataLengthMismatch.selector);
        multi.multiInit(new address[](1), new bytes[](0));
    }

    function testFuzz_FailingMiddleCustomReasonIsDecoded(uint256 value_) public {
        _assertMiddleFailure(
            abi.encodeCall(step.failCustom, (value_)),
            abi.encodeWithSelector(MultiInitExecutionFixture.StepError.selector, value_)
        );
    }

    function test_FailingMiddleStringReasonIsDecoded() public {
        _assertMiddleFailure(
            abi.encodeCall(step.failString, ()), abi.encodeWithSignature("Error(string)", "middle step failed")
        );
    }

    function test_FailingMiddlePanicReasonIsDecoded() public {
        _assertMiddleFailure(abi.encodeCall(step.failPanic, ()), abi.encodeWithSignature("Panic(uint256)", 1));
    }

    function test_FailingMiddleEmptyReasonStillIdentifiesTheStep() public {
        _assertMiddleFailure(abi.encodeCall(step.failEmpty, ()), "");
    }

    function test_ZeroMiddleRevertsAndRollsBackTheCut() public {
        (address[] memory addresses, bytes[] memory data) = _steps();
        addresses[1] = address(0);
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertFalse(ok, "zero step must not silently commit earlier state and skip later steps");
        assertEq(bytes4(result), ExpectedMultiInitErrors.MultiInit__ZeroInit.selector);
        assertEq(abi.decode(_args(result), (uint256)), 1);
        _assertRollback();
    }

    function testFuzz_ZeroAtAnyPositionHasItsExactIndex(uint8 position) public {
        uint256 index = bound(position, 0, 2);
        (address[] memory addresses, bytes[] memory data) = _steps();
        addresses[index] = address(0);
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertFalse(ok, "every zero step fails loudly");
        assertEq(bytes4(result), ExpectedMultiInitErrors.MultiInit__ZeroInit.selector);
        assertEq(abi.decode(_args(result), (uint256)), index);
        _assertRollback();
    }

    function test_MissingCodeMiddleReportsIndexAndAddress() public {
        (address[] memory addresses, bytes[] memory data) = _steps();
        addresses[1] = address(0xDEAD);
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertFalse(ok);
        assertEq(bytes4(result), ExpectedMultiInitErrors.NoBytecodeAtAddress.selector);
        (uint256 index, address failedInit) = abi.decode(_args(result), (uint256, address));
        assertEq(index, 1);
        assertEq(failedInit, address(0xDEAD));
        _assertRollback();
    }

    function test_NestedFailurePreservesOuterAndInnerSteps() public {
        MultiInit nested = new MultiInit();
        (address[] memory innerAddresses, bytes[] memory innerData) = _steps();
        innerData[2] = abi.encodeCall(step.failCustom, (42));
        (address[] memory addresses, bytes[] memory data) = _steps();
        addresses[1] = address(nested);
        data[1] = abi.encodeCall(MultiInit.multiInit, (innerAddresses, innerData));
        (bool ok, bytes memory result) = _cut(addresses, data);
        assertFalse(ok);
        assertEq(bytes4(result), ExpectedMultiInitErrors.MultiInit__StepFailed.selector);
        (uint256 index, address failedInit, bytes memory reason) = abi.decode(_args(result), (uint256, address, bytes));
        assertEq(index, 1);
        assertEq(failedInit, address(nested));
        assertEq(bytes4(reason), ExpectedMultiInitErrors.MultiInit__StepFailed.selector);
        (uint256 innerIndex, address innerInit, bytes memory innerReason) =
            abi.decode(_args(reason), (uint256, address, bytes));
        assertEq(innerIndex, 2);
        assertEq(innerInit, address(step));
        assertEq(innerReason, abi.encodeWithSelector(MultiInitExecutionFixture.StepError.selector, 42));
        _assertRollback();
    }

    function test_FailedFreshInitializationCanRetryTheSameVersion() public {
        MockDiamond fresh = new MockDiamond();
        (address[] memory addresses, bytes[] memory data) = _steps();
        addresses[1] = address(0);
        vm.expectRevert(abi.encodeWithSelector(ExpectedMultiInitErrors.MultiInit__ZeroInit.selector, 1));
        fresh.initialize(_cuts(), address(multi), abi.encodeCall(MultiInit.multiInit, (addresses, data)));
        assertEq(vm.load(address(fresh), VALUE_SLOT), bytes32(0));
        assertEq(vm.load(address(fresh), InitializableLib.initializableSlot()), bytes32(0));
        (bool routed, bytes memory result) = address(fresh).call(abi.encodeCall(step.value, ()));
        assertFalse(routed);
        assertEq(result, abi.encodeWithSelector(FunctionDoesNotExist.selector, step.value.selector));

        addresses[1] = address(step);
        fresh.initialize(_cuts(), address(multi), abi.encodeCall(MultiInit.multiInit, (addresses, data)));
        assertEq(MultiInitExecutionFixture(address(fresh)).value(), 123);
    }
}
