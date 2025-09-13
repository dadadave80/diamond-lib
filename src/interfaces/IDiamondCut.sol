// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FacetCut} from "@diamond-storage/DiamondStorage.sol";

/// @title IDiamondCut
/// @notice Interface for diamond cut (facet add/replace/remove) functionality
interface IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute `data`
    /// @param _data A function call, including function selector and arguments
    ///             `data` is executed with delegatecall on `init`
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _data) external payable;
}
