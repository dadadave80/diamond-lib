// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {DiamondLib, DiamondStorage, Facet} from "@diamond/libraries/DiamondLib.sol";

/// @title DiamondLoupeFacet
/// @notice Provides read-only functions to inspect the state of a Diamond proxy, including facets, function selectors, and supported interfaces
/// @author Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol)
/// @author Modified by David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Implements the IDiamondLoupe interface as defined in EIP-2535
contract DiamondLoupeFacet is IDiamondLoupe {
    /// @notice Gets all facet addresses and their function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_) {
        DiamondStorage storage ds = DiamondLib.diamondStorage();
        uint256 facetCount = ds.facetAddresses.length;
        facets_ = new Facet[](facetCount);
        for (uint256 i; i < facetCount; ++i) {
            address facetAddr = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddr;
            facets_[i].functionSelectors = ds.facetToSelectorsAndPosition[facetAddr].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return The function selectors for the specified facet.
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory) {
        return DiamondLib.diamondStorage().facetToSelectorsAndPosition[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return Facet addresses.
    function facetAddresses() external view override returns (address[] memory) {
        return DiamondLib.diamondStorage().facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return The address of the facet that supports the given selector.
    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return DiamondLib.diamondStorage().selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}
