# Changelog

## Unreleased

### Breaking changes

* `MultiInit` rejects a zero initializer with `MultiInit__ZeroInit(uint256 index)` instead of ending the batch
  successfully. Pass arrays containing exactly the intended steps; remove zero sentinels and unused trailing entries.
* Failed delegatecalls now report `MultiInit__StepFailed(uint256 index, address init, bytes reason)` instead of
  bubbling the inner error or returning `InitializeReverted`. The original revert bytes, including an empty reason,
  are preserved inside `reason`; nested batches retain their indexed error path.
* `MultiInit`'s missing-code error is now `NoBytecodeAtAddress(uint256 index, address initAddress)`. Its indexes are
  zero-based, as are the two errors above. `DiamondLib`'s separate address-only missing-code error is unchanged.

The `multiInit(address[],bytes[])` function signature, length-mismatch error and explicit empty-batch no-op are
unchanged. Every rejected step reverts the enclosing transaction, including prior initialization writes and facet cuts.
These changes require the next minor release under the repository's pre-major versioning policy; no version is set here.

## [0.4.0](https://github.com/dadadave80/diamond-lib/compare/v0.3.0...v0.4.0) (2026-11-06)


### ⚠ BREAKING CHANGES

* Remove zero sentinel entries and pass exactly sized initializer arrays. Decode MultiInit__StepFailed(uint256,address,bytes) instead of bare inner reverts or InitializeReverted, and decode MultiInit NoBytecodeAtAddress(uint256,address) with its new index. The multiInit function signature and DiamondLib errors are unchanged.

### Features

* report indexed MultiInit failures atomically ([#37](https://github.com/dadadave80/diamond-lib/issues/37)) ([a6334d2](https://github.com/dadadave80/diamond-lib/commit/a6334d2329cbde0e314dbb53f058a1350aa8826f))

## [0.3.0](https://github.com/dadadave80/diamond-lib/compare/v0.2.0...v0.3.0) (2026-07-19)


### ⚠ BREAKING CHANGES

* Diamond is abstract with no initialize or receive; InitializableLib and ContextLib are removed from src/.

### Code Refactoring

* make Diamond an abstract fallback-only base ([523bf38](https://github.com/dadadave80/diamond-lib/commit/523bf38d860b8fc306bf7bf91639da981ba7e99a))

## [0.2.0](https://github.com/dadadave80/diamond-lib/compare/v0.1.4...v0.2.0) (2026-07-10)


### Features

* adopt ERC-8153 exportSelectors for on-chain facet self-description ([58de958](https://github.com/dadadave80/diamond-lib/commit/58de958d3e91aacc7d5b9f3d9e28753df021f77f))
* adopt ERC-8153 exportSelectors for on-chain facet self-description ([696ad3d](https://github.com/dadadave80/diamond-lib/commit/696ad3de6e0b0cc07f47466d688d3c79f8a9440a))
