// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Diamond, FacetCut} from "@diamond/Diamond.sol";
import {DiamondLib} from "@diamond/libraries/DiamondLib.sol";
import {InitializableLib} from "@diamond/libraries/InitializableLib.sol";

contract ReinitializableDiamond is Diamond {
    function reinitialize(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata, uint64 _version)
        external
        payable
    {
        bytes32 s = InitializableLib.initializableSlot();
        InitializableLib.preReinitializer(s, _version);

        DiamondLib.diamondCutCalldata(_facetCuts, _init, _calldata);

        InitializableLib.postReinitializer(s, _version);
    }

    function getInitializedVersion() external view returns (uint64) {
        return InitializableLib.getInitializedVersion(InitializableLib.initializableSlot());
    }

    function isInitializing() external view returns (bool) {
        return InitializableLib.isInitializing(InitializableLib.initializableSlot());
    }

    function disableInitializers() external {
        InitializableLib.disableInitializers(InitializableLib.initializableSlot());
    }
}
