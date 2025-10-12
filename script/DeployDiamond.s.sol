// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FacetCut, FacetCutAction} from "@diamond-storage/DiamondStorage.sol";
import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {MockDiamond} from "@diamond-test/mocks/MockDiamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {LibContext} from "@diamond/libraries/LibContext.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
///
/// @dev Uses Foundry's `Script` and a helper contract to deploy and wire up DiamondCutFacet, DiamondLoupeFacet, and OwnableRolesFacet
contract DeployDiamond is Script, GetSelectors {
    /// @notice Executes the deployment of the Diamond contract with the initial facets and ERC165 interface setup
    /// @dev Broadcasts transactions using Foundry's scripting environment (`vm.startBroadcast()` and `vm.stopBroadcast()`).
    ///      Deploys three core facets, sets up DiamondArgs, encodes an initializer call, and constructs the Diamond.
    /// @return diamond_ The address of the deployed Diamond proxy contract
    function run() external returns (address diamond_) {
        vm.startBroadcast();
        // Deploy core facet contracts
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnableRolesFacet ownableRolesFacet = new OwnableRolesFacet();

        // Deploy ERC165 initializer contract
        address diamondInit = address(new DiamondInit());

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](3);

        // Add DiamondCutFacet to the cut list
        cut[0] = FacetCut({
            facetAddress: address(diamondCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondCutFacet")
        });

        // Add DiamondLoupeFacet to the cut list
        cut[1] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondLoupeFacet")
        });

        // Add OwnableRolesFacet to the cut list
        cut[2] = FacetCut({
            facetAddress: address(ownableRolesFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("OwnableRolesFacet")
        });

        // Deploy the Diamond contract with the facets and initialization args
        MockDiamond diamond =
            new MockDiamond(cut, diamondInit, abi.encodeWithSignature("initDiamond(address)", LibContext._msgSender()));
        diamond_ = address(diamond);
        vm.stopBroadcast();
    }
}
