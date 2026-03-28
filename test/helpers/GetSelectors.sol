// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

/// @notice Helper contract for extracting function selectors from facet contracts.
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
abstract contract GetSelectors is Test {
    /// @notice Extracts function selectors from a given facet by reading the artifact file.
    /// @dev Uses `vm.readFile` to read the artifact file and `vm.parseJsonKeys` to extract the method identifiers.
    /// @param _facet The name of the facet contract to inspect.
    /// @return selectors_ An array of function selectors extracted from the facet.
    function _getSelectors(string memory _facet) internal view returns (bytes4[] memory selectors_) {
        string memory path = string.concat("out/", _facet, ".sol/", _facet, ".json");
        // forge-lint: disable-next-line(unsafe-cheatcode)
        string memory artifact = vm.readFile(path);

        string[] memory keys = vm.parseJsonKeys(artifact, "$.methodIdentifiers");
        uint256 keysLength = keys.length;
        selectors_ = new bytes4[](keysLength);

        for (uint256 i; i < keysLength; ++i) {
            selectors_[i] = bytes4(keccak256(bytes(keys[i])));
        }
    }
}
