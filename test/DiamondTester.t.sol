// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Utils} from "@diamond-test/helpers/Utils.sol";
import {DeployedDiamondState} from "@diamond-test/states/DeployedDiamondState.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {Facet} from "@diamond/libraries/DiamondLib.sol";

/// @title DiamondTester
/// @notice Validates the structure and integrity of a freshly deployed Diamond
contract DiamondTester is DeployedDiamondState {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              ROUGH — Post-Deployment Verification            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The rough stone has been set — diamond is deployed
    function testRough_DiamondDeployed() public view {
        assertNotEq(address(diamond), address(0));
    }

    /// @notice The crown holder is established at deployment
    function testRough_OwnerIsSet() public view {
        assertEq(ownable.owner(), address(this));
    }

    /// @notice Exactly 3 standard facets are cut into the rough
    function testRough_StandardFacetsDeployed() public view {
        assertEq(facetAddresses.length, 3);
        for (uint256 i; i < facetAddresses.length; ++i) {
            assertNotEq(address(facetAddresses[i]), address(0));
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              LOUPE — Inspecting the Cut                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Every expected selector is registered under its facet
    function testLoupe_SelectorsAreComplete() public {
        for (uint256 i; i < facetAddresses.length; ++i) {
            bytes4[] memory fromGenSelectors = _getSelectors(facetNames[i]);
            for (uint256 j; j < fromGenSelectors.length; ++j) {
                assertEq(facetAddresses[i], diamondLoupe.facetAddress(fromGenSelectors[j]));
            }
        }
    }

    /// @notice No two facets share a selector — every surface is unique
    function testLoupe_SelectorsAreUnique() public view {
        bytes4[] memory allSelectors = Utils.getAllSelectors(address(diamond));
        for (uint256 i; i < allSelectors.length; ++i) {
            for (uint256 j = i + 1; j < allSelectors.length; ++j) {
                assertNotEq(allSelectors[i], allSelectors[j]);
            }
        }
    }

    /// @notice Forward mapping: selector → facet is consistent
    function testLoupe_SelectorToFacetMapping() public view {
        Facet[] memory facetsList = diamondLoupe.facets();
        for (uint256 i; i < facetsList.length; ++i) {
            for (uint256 j; j < facetsList[i].functionSelectors.length; ++j) {
                bytes4 selector = facetsList[i].functionSelectors[j];
                address expected = facetsList[i].facetAddress;
                assertEq(diamondLoupe.facetAddress(selector), expected);
            }
        }
    }

    /// @notice Reverse mapping: facet → selectors is consistent
    function testLoupe_FacetToSelectorsMapping() public view {
        for (uint256 i; i < facetAddresses.length; ++i) {
            bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(facetAddresses[i]);
            for (uint256 j; j < selectors.length; ++j) {
                assertEq(diamondLoupe.facetAddress(selectors[j]), facetAddresses[i]);
            }
        }
    }

    /// @notice Unregistered facet returns empty selectors
    function testLoupe_UnknownFacetReturnsEmpty() public view {
        bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(address(0xDEAD));
        assertEq(selectors.length, 0);
    }

    /// @notice Unregistered selector returns zero address
    function testLoupe_UnknownSelectorReturnsZero() public view {
        assertEq(diamondLoupe.facetAddress(bytes4(0xdeadbeef)), address(0));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              CERTIFIED — ERC-165 Interface Compliance         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Certified: supports ERC-165 introspection
    function testCertified_SupportsERC165() public view {
        assertTrue(diamondLoupe.supportsInterface(0x01ffc9a7));
    }

    /// @notice Certified: supports ERC-173 ownership
    function testCertified_SupportsERC173() public view {
        assertTrue(diamondLoupe.supportsInterface(0x7f5828d0));
    }

    /// @notice Certified: supports IDiamondCut
    function testCertified_SupportsIDiamondCut() public view {
        assertTrue(diamondLoupe.supportsInterface(type(IDiamondCut).interfaceId));
    }

    /// @notice Certified: supports IDiamondLoupe
    function testCertified_SupportsIDiamondLoupe() public view {
        assertTrue(diamondLoupe.supportsInterface(type(IDiamondLoupe).interfaceId));
    }

    /// @notice Unregistered interface returns false
    function testCertified_UnsupportedInterfaceReturnsFalse() public view {
        assertFalse(diamondLoupe.supportsInterface(0xffffffff));
        assertFalse(diamondLoupe.supportsInterface(bytes4(0xdeadbeef)));
    }
}
