// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {MockDiamond} from "@diamond-test/mocks/MockDiamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {ERC165Facet} from "@diamond/facets/ERC165Facet.sol";
import {OwnableFacet} from "@diamond/facets/OwnableFacet.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {OwnableInit} from "@diamond/initializers/OwnableInit.sol";
import {ContextLib} from "@diamond/libraries/ContextLib.sol";
import {FacetCut, FacetCutAction} from "@diamond/libraries/DiamondLib.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
///
/// @dev Uses Foundry's `Script` and a helper contract to deploy and wire up DiamondCutFacet, DiamondLoupeFacet, and OwnableFacet
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
        ERC165Facet erc165Facet = new ERC165Facet();
        OwnableFacet ownableFacet = new OwnableFacet();

        // Deploy initializer contracts
        address multiInit = address(new MultiInit());
        address diamondInit = address(new DiamondInit());
        address erc165Init = address(new ERC165Init());
        address ownableInit = address(new OwnableInit());

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](4);

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

        // Add ERC165Facet to the cut list
        cut[2] = FacetCut({
            facetAddress: address(erc165Facet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("ERC165Facet")
        });

        // Add OwnableFacet to the cut list
        cut[3] = FacetCut({
            facetAddress: address(ownableFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("OwnableFacet")
        });

        // Build MultiInit arrays for granular initialization
        address[] memory initAddresses = new address[](3);
        bytes[] memory initData = new bytes[](3);

        initAddresses[0] = diamondInit;
        initData[0] = abi.encodeWithSignature("init()");

        initAddresses[1] = erc165Init;
        initData[1] = abi.encodeWithSignature("init()");

        initAddresses[2] = ownableInit;
        initData[2] = abi.encodeWithSignature("init(address)", ContextLib.msgSender());

        // Deploy the Diamond contract with the facets and initialization args
        MockDiamond diamond = new MockDiamond();
        diamond.initialize(
            cut, multiInit, abi.encodeWithSignature("multiInit(address[],bytes[])", initAddresses, initData)
        );
        diamond_ = address(diamond);
        vm.stopBroadcast();
    }
}
