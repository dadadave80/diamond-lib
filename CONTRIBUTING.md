# Contributing to Diamond Lib

Thanks for your interest in contributing! This is a reusable Foundry library for the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535), so contributions that improve reliability, gas efficiency, or developer experience are welcome.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Familiarity with the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)

## Setup

```sh
git clone https://github.com/dadadave80/diamond-lib.git
cd diamond-lib
forge install
forge build
```

## Running Tests

Tests use FFI for selector extraction, so the `--ffi` flag is required:

```sh
forge test --ffi -vvv
```

## Making Changes

1. Fork the repo and create a branch from `main`.
2. Make your changes in the appropriate directory:
   - `src/facets/` — Facet contracts
   - `src/libraries/` — Core libraries
   - `src/interfaces/` — Interfaces
   - `src/initializers/` — Initializer contracts
3. Add or update tests in `test/` to cover your changes.
4. Run `forge fmt` to format your code.
5. Ensure all tests pass with `forge test --ffi`.
6. Open a pull request against `main`.

## Guidelines

- Keep gas efficiency in mind — this library is optimized for minimal overhead.
- Follow existing code style and naming conventions.
- One logical change per PR — avoid bundling unrelated changes.
- Include test cases for both success and failure paths.

## Reporting Issues

If you find a bug, please open an issue with:
- A clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior

For security vulnerabilities, please follow the process in [SECURITY.md](SECURITY.md) instead.
