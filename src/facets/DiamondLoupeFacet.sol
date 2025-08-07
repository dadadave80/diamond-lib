// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DiamondStorage, LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {Facet} from "@diamond/libraries/types/DiamondStorage.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @notice Provides read-only functions to inspect the state of a Diamond proxy, including facets, function selectors, and supported interfaces
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/facets/DiamondLoupeFacet.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/facets/DiamondLoupeFacet.sol)
///
/// @dev Implements the IDiamondLoupe interface as defined in EIP-2535
contract DiamondLoupeFacet is IDiamondLoupe {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Gets all facet addresses and their function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_) {
        DiamondStorage storage ds = LibDiamond._diamondStorage();
        uint256 facetCount = ds.facetAddresses.length();
        facets_ = new Facet[](facetCount);
        for (uint256 facet; facet < facetCount;) {
            address facetAddr = ds.facetAddresses.at(facet);
            facets_[facet].facetAddress = facetAddr;
            facets_[facet].functionSelectors = bytes32SetToBytes4(ds.facetToSelectors[facetAddr].values());
            unchecked {
                ++facet;
            }
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory) {
        return bytes32SetToBytes4(LibDiamond._diamondStorage().facetToSelectors[_facet].values());
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory) {
        return LibDiamond._diamondStorage().facetAddresses.values();
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return LibDiamond._diamondStorage().selectorToFacet[_functionSelector];
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return LibDiamond._diamondStorage().supportedInterfaces[_interfaceId];
    }

    function bytes32SetToBytes4(bytes32[] memory _data) private pure returns (bytes4[] memory result_) {
        assembly ("memory-safe") {
            result_ := _data
        }
    }
}
