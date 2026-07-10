// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployDiamond} from "@diamond-script/DeployDiamond.s.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {ERC165Facet} from "@diamond/facets/ERC165Facet.sol";
import {OwnableFacet} from "@diamond/facets/OwnableFacet.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {Test} from "forge-std/Test.sol";

/// @notice Provides shared state for tests involving a freshly deployed Diamond contract.
/// @dev Sets up references to deployed facets, interfaces, and the diamond itself for testing.
abstract contract DeployedDiamondState is Test {
    DeployDiamond deployDiamond;
    /// @notice Instance of the deployed Diamond contract.
    address public diamond;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    IDiamondCut public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    DiamondLoupeFacet public diamondLoupe;

    /// @notice Interface for the ERC165 functionality of the deployed diamond.
    ERC165Facet public erc165;

    /// @notice Interface for the OwnableRoles functionality of the deployed diamond.
    OwnableFacet public ownable;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    address public diamondOwner = address(this);

    /// @notice Deploys the Diamond contract and initializes interface references and facet addresses.
    /// @dev This function is intended to be called in a test setup phase (e.g., `setUp()` in Foundry).
    function setUp() public virtual {
        deployDiamond = new DeployDiamond();
        diamond = deployDiamond.run();

        diamondCut = IDiamondCut(diamond);
        diamondLoupe = DiamondLoupeFacet(diamond);
        erc165 = ERC165Facet(diamond);
        ownable = OwnableFacet(diamond);

        facetAddresses = diamondLoupe.facetAddresses();
    }
}
