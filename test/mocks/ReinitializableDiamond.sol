// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockDiamond} from "@diamond-test/mocks/MockDiamond.sol";
import {DiamondLib, FacetCut} from "@diamond/libraries/DiamondLib.sol";

contract ReinitializableDiamond is MockDiamond {
    function reinitialize(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata, uint64 _version)
        external
        payable
        reinitializer(_version)
    {
        DiamondLib.diamondCut(_facetCuts, _init, _calldata);
    }

    function getInitializedVersion() external view returns (uint64) {
        return _getInitializedVersion();
    }

    function isInitializing() external view returns (bool) {
        return _isInitializing();
    }

    function disableInitializers() external {
        _disableInitializers();
    }
}
