// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IFacet
/// @notice ERC-8153 facet self-description interface.
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
///
/// @dev Every facet reports its own function selectors on-chain, so upgraders and
///      deployment tooling no longer depend on off-chain selector extraction.
///      See https://eips.ethereum.org/EIPS/eip-8153.
///
/// @custom:security Selectors are SELF-REPORTED by the facet. Only build `FacetCut`s from the
///      `exportSelectors()` of facets whose bytecode you trust (e.g. facets you deployed
///      yourself). A malicious facet can claim selectors it does not implement — including
///      `diamondCut` or ownership selectors — to hijack routing. `Add` cuts fail closed on
///      selector collision, but `Replace` cuts and cuts on a fresh diamond do not.
interface IFacet {
    /// @notice Returns this facet's externally-callable function selectors, ABI-packed.
    /// @dev The returned length is always a multiple of 4. `exportSelectors` MUST exclude
    ///      itself: it is called directly on the facet address, never routed through the
    ///      diamond, and every facet declares it (routing it would collide across facets).
    /// @return selectors_ The facet's selectors packed as consecutive 4-byte values.
    function exportSelectors() external pure returns (bytes memory selectors_);
}
