// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Thrown when decoding a selector payload whose length is not a multiple of 4.
error Selectors__LengthNotMultipleOf4(uint256 length);

/// @notice Decodes ERC-8153 `exportSelectors()` output (packed 4-byte selectors) into a `bytes4[]`.
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Replaces the previous off-chain FFI selector extraction (`GetSelectors.sol`). Selectors are
///      now read on-chain from each facet via `IFacet.exportSelectors()` — no `--ffi` flag required.
///      Usage: `Selectors.decode(IFacet(facet).exportSelectors())`.
///
/// @custom:security The `IFacet(facet).exportSelectors()` payload is SELF-REPORTED by the facet.
///      Only decode-and-cut selectors from facets you trust (e.g. facets you deployed). A malicious
///      facet can report selectors it does not implement to hijack routing — see `IFacet`.
library Selectors {
    /// @notice Decodes ABI-packed 4-byte selectors into a `bytes4[]`.
    /// @dev Reverts if `_packed.length` is not a multiple of 4 (a malformed ERC-8153 payload).
    /// @param _packed Consecutive 4-byte selectors.
    /// @return selectors_ The unpacked selectors.
    function decode(bytes memory _packed) internal pure returns (bytes4[] memory selectors_) {
        if (_packed.length % 4 != 0) revert Selectors__LengthNotMultipleOf4(_packed.length);
        uint256 n = _packed.length / 4;
        selectors_ = new bytes4[](n);
        for (uint256 i; i < n; ++i) {
            uint256 o = i * 4;
            selectors_[i] = bytes4(
                (uint32(uint8(_packed[o])) << 24) | (uint32(uint8(_packed[o + 1])) << 16)
                    | (uint32(uint8(_packed[o + 2])) << 8) | uint32(uint8(_packed[o + 3]))
            );
        }
    }
}
