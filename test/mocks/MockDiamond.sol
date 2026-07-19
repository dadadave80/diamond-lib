// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@diamond-test/utils/Initializable.sol";
import {Diamond} from "@diamond/Diamond.sol";
import {DiamondLib, FacetCut} from "@diamond/libraries/DiamondLib.sol";

/// @notice Reference initializable diamond: the abstract `Diamond` base composed
/// with `Initializable` for factory/CREATE2 deployments where a constructor cut
/// cannot run per-instance.
contract MockDiamond is Diamond, Initializable {
    /// @notice Adds the provided facets and runs the initialization contract, at most once
    /// @param _init Address of the initialization contract
    /// @param _calldata Calldata to be passed to the initialization contract
    function initialize(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata)
        public
        payable
        virtual
        initializer
    {
        DiamondLib.diamondCut(_facetCuts, _init, _calldata);
    }

    receive() external payable virtual {}
}
