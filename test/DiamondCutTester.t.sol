// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockDiamond} from "@diamond-test/mocks/MockDiamond.sol";
import {MockFacetA} from "@diamond-test/mocks/MockFacetA.sol";
import {MockFacetB} from "@diamond-test/mocks/MockFacetB.sol";
import {MockRevertInit} from "@diamond-test/mocks/MockRevertInit.sol";
import {DeployedDiamondState} from "@diamond-test/states/DeployedDiamondState.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {
    AddressAndCalldataLengthMismatch,
    InitializeReverted,
    NoBytecodeAtAddress as MultiInitNoBytecodeAtAddress
} from "@diamond/initializers/MultiInit.sol";
import {OwnableInit} from "@diamond/initializers/OwnableInit.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {
    CannotAddFunctionToDiamondThatAlreadyExists,
    CannotAddSelectorsToZeroAddress,
    CannotRemoveFunctionThatDoesNotExist,
    CannotRemoveImmutableFunction,
    CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet,
    DiamondCut,
    Facet,
    FacetCut,
    FacetCutAction,
    FunctionDoesNotExist,
    InitializeDiamondCutReverted,
    NoBytecodeAtAddress,
    NoSelectorsGivenToAdd,
    NoSelectorsProvidedForFacetCut,
    RemoveFacetAddressMustBeZeroAddress
} from "@diamond/libraries/DiamondLib.sol";
import {OwnableRolesLib} from "@diamond/libraries/OwnableRolesLib.sol";

/// @title DiamondCutTester
/// @notice Extensive test coverage for ERC-2535 diamond cut operations
contract DiamondCutTester is DeployedDiamondState {
    MockFacetA mockFacetA;
    MockFacetB mockFacetB;
    MockRevertInit mockRevertInit;

    address nonOwner = address(0xBEEF);

    function setUp() public override {
        super.setUp();
        mockFacetA = new MockFacetA();
        mockFacetB = new MockFacetB();
        mockRevertInit = new MockRevertInit();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              BRUTING — Shaping with New Facets                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Adding a new facet registers all its selectors
    function testBruting_AddNewFacet() public {
        _addMockFacetA();

        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA1.selector), address(mockFacetA));
        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA2.selector), address(mockFacetA));
        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA3.selector), address(mockFacetA));
    }

    /// @notice New facet appears in the loupe's facet list
    function testBruting_FacetVisibleInLoupe() public {
        _addMockFacetA();

        address[] memory addresses = diamondLoupe.facetAddresses();
        assertEq(addresses.length, 4); // 3 core + MockFacetA

        bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(address(mockFacetA));
        assertEq(selectors.length, 3);
    }

    /// @notice Multiple facets can be added in a single diamond cut
    function testBruting_MultipleFacetsInSingleCut() public {
        FacetCut[] memory cuts = new FacetCut[](2);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, _mockFacetASelectors());

        bytes4[] memory bSelectors = new bytes4[](1);
        bSelectors[0] = MockFacetB.funcB1.selector;
        cuts[1] = FacetCut(address(mockFacetB), FacetCutAction.Add, bSelectors);

        diamondCut.diamondCut(cuts, address(0), "");

        assertEq(diamondLoupe.facetAddresses().length, 5); // 3 core + A + B
    }

    /// @notice Diamond cut emits the DiamondCut event — the fire of the forge
    function testBruting_EmitsDiamondCutFire() public {
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, _mockFacetASelectors());

        vm.expectEmit(false, false, false, false);
        emit DiamondCut(cuts, address(0), "");

        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Delegated call through fallback returns correct data — the brilliance of the cut
    function testBruting_FacetDelegationReturnsBrilliance() public {
        _addMockFacetA();

        assertEq(MockFacetA(address(diamond)).funcA1(), 1);
        assertEq(MockFacetA(address(diamond)).funcA2(), 2);
        assertEq(MockFacetA(address(diamond)).funcA3(), 3);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              RECUTTING — Replacing Facet Implementations      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Replacing a selector routes to the new facet
    function testRecutting_ReplaceFacetImplementation() public {
        _addMockFacetA();
        assertEq(MockFacetA(address(diamond)).funcA1(), 1);

        // Recut funcA1 from MockFacetA → MockFacetB
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetB), FacetCutAction.Replace, selectors);
        diamondCut.diamondCut(cuts, address(0), "");

        assertEq(MockFacetB(address(diamond)).funcA1(), 100);
        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA1.selector), address(mockFacetB));
    }

    /// @notice Replacing one selector does not disturb the other facets
    function testRecutting_PreservesOtherSelectors() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetB), FacetCutAction.Replace, selectors);
        diamondCut.diamondCut(cuts, address(0), "");

        // funcA2 and funcA3 still point to MockFacetA
        assertEq(MockFacetA(address(diamond)).funcA2(), 2);
        assertEq(MockFacetA(address(diamond)).funcA3(), 3);
        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA2.selector), address(mockFacetA));
    }

    /// @notice Replace emits DiamondCut event
    function testRecutting_EmitsDiamondCutFire() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetB), FacetCutAction.Replace, selectors);

        vm.expectEmit(false, false, false, false);
        emit DiamondCut(cuts, address(0), "");

        diamondCut.diamondCut(cuts, address(0), "");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              CLEAVING — Removing Selectors                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Removing a single selector unregisters it from the diamond
    function testCleaving_RemoveSingleSelector() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, selectors);
        diamondCut.diamondCut(cuts, address(0), "");

        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA1.selector), address(0));
        // Others still work
        assertEq(MockFacetA(address(diamond)).funcA2(), 2);
    }

    /// @notice Removing all selectors removes the facet entirely
    function testCleaving_RemoveAllSelectorsRemovesFacet() public {
        _addMockFacetA();
        assertEq(diamondLoupe.facetAddresses().length, 4);

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, _mockFacetASelectors());
        diamondCut.diamondCut(cuts, address(0), "");

        assertEq(diamondLoupe.facetAddresses().length, 3);
        assertEq(diamondLoupe.facetFunctionSelectors(address(mockFacetA)).length, 0);
    }

    /// @notice Removing a subset of selectors keeps the facet with remaining selectors
    function testCleaving_RemoveSubsetPreservesFacet() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MockFacetA.funcA1.selector;
        selectors[1] = MockFacetA.funcA2.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, selectors);
        diamondCut.diamondCut(cuts, address(0), "");

        assertEq(diamondLoupe.facetAddresses().length, 4); // Facet still present
        assertEq(diamondLoupe.facetFunctionSelectors(address(mockFacetA)).length, 1);
        assertEq(MockFacetA(address(diamond)).funcA3(), 3);
    }

    /// @notice Remove emits DiamondCut event
    function testCleaving_EmitsDiamondCutFire() public {
        _addMockFacetA();

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, _mockFacetASelectors());

        vm.expectEmit(false, false, false, false);
        emit DiamondCut(cuts, address(0), "");

        diamondCut.diamondCut(cuts, address(0), "");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              INCLUSIONS — Flaws that Must Revert             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Cannot add selectors to the zero address
    function testInclusion_CannotAddToZeroAddress() public {
        bytes4[] memory selectors = _mockFacetASelectors();
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Add, selectors);

        vm.expectRevert(abi.encodeWithSelector(CannotAddSelectorsToZeroAddress.selector, selectors));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot add a selector that already exists in the diamond
    function testInclusion_CannotAddExistingSelector() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetB), FacetCutAction.Add, selectors);

        vm.expectRevert(
            abi.encodeWithSelector(CannotAddFunctionToDiamondThatAlreadyExists.selector, MockFacetA.funcA1.selector)
        );
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot add with an empty selector array
    function testInclusion_CannotAddEmptySelectors() public {
        bytes4[] memory empty = new bytes4[](0);
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, empty);

        vm.expectRevert(NoSelectorsGivenToAdd.selector);
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot add a facet with no deployed bytecode
    function testInclusion_CannotAddFacetWithoutBytecode() public {
        address noBytecode = address(0xDEAD);
        bytes4[] memory selectors = _mockFacetASelectors();
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(noBytecode, FacetCutAction.Add, selectors);

        vm.expectRevert(abi.encodeWithSelector(NoBytecodeAtAddress.selector, noBytecode));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot replace a selector with the same facet — a pointless recut
    function testInclusion_CannotReplaceSameFacet() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Replace, selectors);

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet.selector, MockFacetA.funcA1.selector
            )
        );
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot replace selectors to the zero address
    function testInclusion_CannotReplaceToZeroAddress() public {
        _addMockFacetA();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacetA.funcA1.selector;
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Replace, selectors);

        vm.expectRevert(abi.encodeWithSelector(CannotAddSelectorsToZeroAddress.selector, selectors));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot replace with an empty selector array
    function testInclusion_CannotReplaceEmptySelectors() public {
        bytes4[] memory empty = new bytes4[](0);
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetB), FacetCutAction.Replace, empty);

        vm.expectRevert(NoSelectorsGivenToAdd.selector);
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Remove facet address must be zero — anything else is a flaw
    function testInclusion_CannotRemoveWithNonZeroAddress() public {
        _addMockFacetA();

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Remove, _mockFacetASelectors());

        vm.expectRevert(abi.encodeWithSelector(RemoveFacetAddressMustBeZeroAddress.selector, address(mockFacetA)));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot remove a selector that doesn't exist
    function testInclusion_CannotRemoveNonExistentSelector() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(0xdeadbeef);
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, selectors);

        vm.expectRevert(abi.encodeWithSelector(CannotRemoveFunctionThatDoesNotExist.selector, bytes4(0xdeadbeef)));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Cannot remove with an empty selector array
    function testInclusion_CannotRemoveEmptySelectors() public {
        bytes4[] memory empty = new bytes4[](0);
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(0), FacetCutAction.Remove, empty);

        vm.expectRevert(abi.encodeWithSelector(NoSelectorsProvidedForFacetCut.selector, address(0)));
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /// @notice Init address with no bytecode reverts
    function testInclusion_InitNoBytecodeReverts() public {
        address noBytecode = address(0xDEAD);
        FacetCut[] memory cuts = new FacetCut[](0);

        vm.expectRevert(abi.encodeWithSelector(NoBytecodeAtAddress.selector, noBytecode));
        diamondCut.diamondCut(cuts, noBytecode, abi.encodeWithSignature("init()"));
    }

    /// @notice Init contract that reverts with data bubbles up the error
    function testInclusion_InitRevertBubblesUp() public {
        FacetCut[] memory cuts = new FacetCut[](0);

        vm.expectRevert(MockRevertInit.CustomInitError.selector);
        diamondCut.diamondCut(
            cuts, address(mockRevertInit), abi.encodeWithSelector(MockRevertInit.initWithError.selector)
        );
    }

    /// @notice Init contract that reverts without data triggers InitializeDiamondCutReverted
    function testInclusion_InitRevertNoDataWrapsError() public {
        FacetCut[] memory cuts = new FacetCut[](0);
        bytes memory callData = abi.encodeWithSelector(MockRevertInit.initNoData.selector);

        vm.expectRevert(
            abi.encodeWithSelector(InitializeDiamondCutReverted.selector, address(mockRevertInit), callData)
        );
        diamondCut.diamondCut(cuts, address(mockRevertInit), callData);
    }

    /// @notice Calling a non-existent selector through fallback reverts
    function testInclusion_NonExistentSelectorReverts() public {
        (bool success, bytes memory returnData) = address(diamond).call(abi.encodeWithSelector(bytes4(0xdeadbeef)));
        assertFalse(success);
        assertEq(bytes4(returnData), FunctionDoesNotExist.selector);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              PRONG — Only the Owner Can Cut                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Owner can perform diamond cuts
    function testProng_OwnerCanCut() public {
        _addMockFacetA();
        assertEq(diamondLoupe.facetAddress(MockFacetA.funcA1.selector), address(mockFacetA));
    }

    /// @notice Non-owner is rejected — the prong holds firm
    function testProng_NonOwnerCannotCut() public {
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, _mockFacetASelectors());

        vm.prank(nonOwner);
        vm.expectRevert(OwnableRolesLib.Unauthorized.selector);
        diamondCut.diamondCut(cuts, address(0), "");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SETTING — MultiInit Error Paths                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice MultiInit reverts on mismatched array lengths
    function testSetting_MultiInitMismatchedArrays() public {
        MultiInit multiInit = new MultiInit();

        address[] memory addrs = new address[](2);
        bytes[] memory data = new bytes[](1); // mismatch
        addrs[0] = address(mockRevertInit);
        addrs[1] = address(mockRevertInit);
        data[0] = abi.encodeWithSelector(MockRevertInit.initWithError.selector);

        bytes memory callData = abi.encodeWithSignature("multiInit(address[],bytes[])", addrs, data);

        vm.expectRevert(AddressAndCalldataLengthMismatch.selector);
        diamondCut.diamondCut(new FacetCut[](0), address(multiInit), callData);
    }

    /// @notice MultiInit reverts when an init address has no bytecode
    function testSetting_MultiInitNoBytecodeReverts() public {
        MultiInit multiInit = new MultiInit();

        address[] memory addrs = new address[](1);
        bytes[] memory data = new bytes[](1);
        addrs[0] = address(0xDEAD); // no bytecode
        data[0] = abi.encodeWithSignature("init()");

        bytes memory callData = abi.encodeWithSignature("multiInit(address[],bytes[])", addrs, data);

        vm.expectRevert(abi.encodeWithSelector(MultiInitNoBytecodeAtAddress.selector, address(0xDEAD)));
        diamondCut.diamondCut(new FacetCut[](0), address(multiInit), callData);
    }

    /// @notice MultiInit bubbles up init contract revert errors
    function testSetting_MultiInitRevertBubblesUp() public {
        MultiInit multiInit = new MultiInit();

        address[] memory addrs = new address[](1);
        bytes[] memory data = new bytes[](1);
        addrs[0] = address(mockRevertInit);
        data[0] = abi.encodeWithSelector(MockRevertInit.initWithError.selector);

        bytes memory callData = abi.encodeWithSignature("multiInit(address[],bytes[])", addrs, data);

        vm.expectRevert(MockRevertInit.CustomInitError.selector);
        diamondCut.diamondCut(new FacetCut[](0), address(multiInit), callData);
    }

    /// @notice MultiInit stops processing on address(0) — the sentinel stone
    function testSetting_MultiInitStopsOnZeroAddress() public {
        MultiInit multiInit = new MultiInit();
        ERC165Init erc165Init = new ERC165Init();

        address[] memory addrs = new address[](2);
        bytes[] memory data = new bytes[](2);
        addrs[0] = address(0); // sentinel — stops here
        addrs[1] = address(erc165Init); // should not execute
        data[0] = "";
        data[1] = abi.encodeWithSignature("initERC165()");

        bytes memory callData = abi.encodeWithSignature("multiInit(address[],bytes[])", addrs, data);

        // Should succeed (early return on address(0)), not revert
        diamondCut.diamondCut(new FacetCut[](0), address(multiInit), callData);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              BRILLIANCE — ETH Handling & Delegation          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Diamond can receive ETH via receive()
    function testBrilliance_ReceiveAcceptsETH() public {
        vm.deal(address(this), 1 ether);
        (bool success,) = address(diamond).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(diamond).balance, 1 ether);
    }

    /// @notice Diamond cut with init can forward ETH
    function testBrilliance_DiamondCutWithInitIsPayable() public {
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, _mockFacetASelectors());
        // Payable call — should not revert
        diamondCut.diamondCut{value: 0}(cuts, address(0), "");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        HELPERS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _mockFacetASelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](3);
        s[0] = MockFacetA.funcA1.selector;
        s[1] = MockFacetA.funcA2.selector;
        s[2] = MockFacetA.funcA3.selector;
    }

    function _addMockFacetA() internal {
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut(address(mockFacetA), FacetCutAction.Add, _mockFacetASelectors());
        diamondCut.diamondCut(cuts, address(0), "");
    }
}
