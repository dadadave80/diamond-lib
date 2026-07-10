// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Selectors, Selectors__LengthNotMultipleOf4} from "@diamond-test/helpers/Selectors.sol";
import {Utils} from "@diamond-test/helpers/Utils.sol";
import {MockFacetA} from "@diamond-test/mocks/MockFacetA.sol";
import {MockFacetB} from "@diamond-test/mocks/MockFacetB.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {ERC165Facet} from "@diamond/facets/ERC165Facet.sol";
import {OwnableFacet} from "@diamond/facets/OwnableFacet.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {IFacet} from "@diamond/interfaces/IFacet.sol";
import {Test} from "forge-std/Test.sol";

/// @title ExportSelectorsTester
/// @notice Verifies each facet's ERC-8153 `exportSelectors()` output and the `Selectors` decoder.
/// @dev Expected selector sets are listed from an INDEPENDENT source (interface constants,
///      contract-qualified externals, instance-form refs) — never re-derived from
///      `exportSelectors()` — so these assertions cannot pass by self-agreement.
contract ExportSelectorsTester is Test {
    DiamondCutFacet cut;
    DiamondLoupeFacet loupe;
    ERC165Facet erc165;
    OwnableFacet ownable;
    MockFacetA mockA;
    MockFacetB mockB;

    function setUp() public {
        cut = new DiamondCutFacet();
        loupe = new DiamondLoupeFacet();
        erc165 = new ERC165Facet();
        ownable = new OwnableFacet();
        mockA = new MockFacetA();
        mockB = new MockFacetB();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                EXACT-SET ASSERTIONS PER FACET             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice DiamondCutFacet exports exactly its `diamondCut` selector.
    function testExport_DiamondCut() public view {
        bytes4[] memory expected = new bytes4[](1);
        expected[0] = IDiamondCut.diamondCut.selector;
        _assertExports(IFacet(address(cut)), expected);
    }

    /// @notice DiamondLoupeFacet exports exactly its four loupe selectors.
    function testExport_Loupe() public view {
        bytes4[] memory expected = new bytes4[](4);
        expected[0] = IDiamondLoupe.facets.selector;
        expected[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        expected[2] = IDiamondLoupe.facetAddresses.selector;
        expected[3] = IDiamondLoupe.facetAddress.selector;
        _assertExports(IFacet(address(loupe)), expected);
    }

    /// @notice ERC165Facet exports exactly its `supportsInterface` selector.
    function testExport_ERC165() public view {
        bytes4[] memory expected = new bytes4[](1);
        expected[0] = ERC165Facet.supportsInterface.selector;
        _assertExports(IFacet(address(erc165)), expected);
    }

    /// @notice OwnableFacet exports exactly its seven ownership selectors.
    function testExport_Ownable() public view {
        bytes4[] memory expected = new bytes4[](7);
        expected[0] = ownable.transferOwnership.selector;
        expected[1] = ownable.renounceOwnership.selector;
        expected[2] = ownable.requestOwnershipHandover.selector;
        expected[3] = ownable.cancelOwnershipHandover.selector;
        expected[4] = ownable.completeOwnershipHandover.selector;
        expected[5] = ownable.owner.selector;
        expected[6] = ownable.ownershipHandoverExpiresAt.selector;
        _assertExports(IFacet(address(ownable)), expected);
    }

    /// @notice MockFacetA exports exactly its three selectors.
    function testExport_MockA() public view {
        bytes4[] memory expected = new bytes4[](3);
        expected[0] = MockFacetA.funcA1.selector;
        expected[1] = MockFacetA.funcA2.selector;
        expected[2] = MockFacetA.funcA3.selector;
        _assertExports(IFacet(address(mockA)), expected);
    }

    /// @notice MockFacetB exports exactly its two selectors.
    function testExport_MockB() public view {
        bytes4[] memory expected = new bytes4[](2);
        expected[0] = MockFacetB.funcA1.selector;
        expected[1] = MockFacetB.funcB1.selector;
        _assertExports(IFacet(address(mockB)), expected);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 INVARIANTS ACROSS ALL FACETS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice ERC-8153: every facet's packed payload is non-empty and a multiple of 4 bytes.
    function testExport_LengthIsNonZeroMultipleOf4() public view {
        IFacet[6] memory facets = _allFacets();
        for (uint256 i; i < facets.length; ++i) {
            bytes memory packed = facets[i].exportSelectors();
            assertGt(packed.length, 0, "empty selector payload");
            assertEq(packed.length % 4, 0, "payload not a multiple of 4");
        }
    }

    /// @notice ERC-8153: `exportSelectors` MUST NOT include its own selector.
    function testExport_ExcludesItself() public view {
        IFacet[6] memory facets = _allFacets();
        for (uint256 i; i < facets.length; ++i) {
            bytes4[] memory sels = Selectors.decode(facets[i].exportSelectors());
            for (uint256 j; j < sels.length; ++j) {
                assertTrue(sels[j] != IFacet.exportSelectors.selector, "must exclude exportSelectors");
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      SELECTORS DECODER                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice `decode` inverts tight 4-byte packing for any selector set.
    function testFuzz_DecodeRoundTrip(bytes4[] memory _sels) public pure {
        bytes memory packed;
        for (uint256 i; i < _sels.length; ++i) {
            packed = abi.encodePacked(packed, _sels[i]);
        }
        bytes4[] memory got = Selectors.decode(packed);
        assertEq(got.length, _sels.length);
        for (uint256 i; i < _sels.length; ++i) {
            assertEq(got[i], _sels[i]);
        }
    }

    /// @notice `decode` of an empty payload yields an empty array.
    function testDecode_Empty() public pure {
        assertEq(Selectors.decode("").length, 0);
    }

    /// @notice `decode` reverts when the payload length is not a multiple of 4.
    function testDecode_RevertsOnNonMultipleOf4() public {
        // Routed through an external call so `expectRevert` sees the revert at a lower depth
        // (the library function is `internal` and would otherwise be inlined at this depth).
        vm.expectRevert(abi.encodeWithSelector(Selectors__LengthNotMultipleOf4.selector, uint256(3)));
        this.decodeExternal(hex"abcdef");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev External wrapper so `decode` reverts can be asserted with `vm.expectRevert`.
    function decodeExternal(bytes calldata _packed) external pure returns (bytes4[] memory selectors_) {
        selectors_ = Selectors.decode(_packed);
    }

    function _allFacets() internal view returns (IFacet[6] memory facets_) {
        facets_ = [
            IFacet(address(cut)),
            IFacet(address(loupe)),
            IFacet(address(erc165)),
            IFacet(address(ownable)),
            IFacet(address(mockA)),
            IFacet(address(mockB))
        ];
    }

    function _assertExports(IFacet _facet, bytes4[] memory _expected) internal view {
        bytes4[] memory got = Selectors.decode(_facet.exportSelectors());
        assertEq(got.length, _expected.length, "selector count mismatch");
        for (uint256 i; i < _expected.length; ++i) {
            assertTrue(Utils.containsElement(got, _expected[i]), "expected selector missing");
        }
        for (uint256 i; i < got.length; ++i) {
            assertTrue(Utils.containsElement(_expected, got[i]), "unexpected selector present");
        }
    }
}
