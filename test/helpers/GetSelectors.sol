// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

/// @notice Helper contract for extracting function selectors from facet contracts.
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
abstract contract GetSelectors is Test {
    /// @notice Extracts function selectors from a given facet using `forge inspect` via FFI.
    /// @dev Uses FFI to call `forge inspect <facet> methodIdentifiers` which returns only
    ///      the small methodIdentifiers JSON, avoiding the full artifact dump in traces.
    /// @param _facet The name of the facet contract to inspect.
    /// @return selectors_ An array of function selectors extracted from the facet.
    function _getSelectors(string memory _facet) internal returns (bytes4[] memory selectors_) {
        string[] memory cmd = new string[](5);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facet;
        cmd[3] = "methodIdentifiers";
        cmd[4] = "--json";

        string memory json = string(vm.ffi(cmd));
        string[] memory signatures = vm.parseJsonKeys(json, "");
        uint256 len = signatures.length;
        selectors_ = new bytes4[](len);

        for (uint256 i; i < len; ++i) {
            selectors_[i] = bytes4(keccak256(bytes(signatures[i])));
        }
    }
}
