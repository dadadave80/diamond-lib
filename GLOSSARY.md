# Diamond Library Glossary

A comprehensive reference for Diamond pattern terminology and concepts.

---

## Core Concepts

### Diamond
The main proxy contract that users interact with. It has:
- **Persistent address** - Users always call the same address
- **Dynamic routing** - Routes calls to different facets based on function selector
- **Shared storage** - All facets access the same storage space
- **Modular upgrades** - Functions can be added, replaced, or removed without contract migration

**Example**: A Diamond at `0x1234...` might expose functions from 5 different facets.

### Facet
A separate smart contract containing related functions that execute in the Diamond's storage context.

**Key properties**:
- Deployed once, never updated directly
- Contains function implementations
- All code executes in Diamond's storage via `delegatecall`
- Can be added, replaced, or removed from Diamond
- Multiple facets can exist simultaneously

**Example**: `ERC20Facet` contains `transfer()`, `approve()`, `balanceOf()`

### Function Selector
The first 4 bytes of a function's Keccak256 hash.

```solidity
keccak256("transfer(address,uint256)") = 0xa9059cbb... (32 bytes)
selector = 0xa9059cbb (first 4 bytes)
```

**Purpose**: 
- Compact function identification
- Gas-efficient routing in fallback
- Enables function replacement

**Example**: `0x06fdde03` is the selector for `name()` in ERC20

### Diamond Cut
An atomic transaction that modifies which functions the Diamond exposes.

**Three operations**:
- **Add**: Introduce functions from a new facet
- **Replace**: Change a function's implementation (different facet)
- **Remove**: Delete a function from the Diamond

**Atomicity**: All operations succeed together or fail together.

**Example**:
```solidity
// Add 10 ERC20 functions from TokenFacet
// Replace 3 governance functions with ImprovedGovernanceFacet
// Remove 2 deprecated functions
// All happen in one transaction
```

### Loupe
Functions that inspect the Diamond's composition (like a jeweler's loupe).

**Loupe functions**:
- `facets()` - Get all facets and their selectors
- `facetAddresses()` - Get list of all facet addresses
- `facetFunctionSelectors(address)` - Get selectors from specific facet
- `facetAddress(bytes4)` - Find facet for a selector

**Purpose**: Verify what functions the Diamond exposes and which facet implements each.

---

## Storage & Architecture

### Storage Slot
A 32-byte location in contract storage.

**Diamond storage**:
- Multiple values can be packed into one slot
- ERC-7201 namespacing prevents collisions
- Libraries use fixed locations for consistency

**Example**: Owner stored in single slot for gas efficiency

### ERC-7201 Namespaced Storage
A pattern for allocating isolated storage to components.

**Formula**:
```solidity
uint256 slot = uint256(keccak256(abi.encode(
    uint256(keccak256("namespace")) - 1
))) & ~bytes32(uint256(0xff));
```

**Benefit**: Each component gets unique namespace; no collisions

**Example**:
- Diamond storage uses namespace: `"diamond.lib.storage"`
- Owner storage uses: (internal to OwnableLib)
- Custom facets can use: `"my.storage.v1"`

### Delegatecall
EVM operation that executes code from one contract in another's storage context.

**How Diamond uses it**:
```
fallback() calls delegatecall(facet, calldata)
→ Facet code executes
→ Reads/writes Diamond's storage
→ Returns to Diamond
→ Diamond returns to caller
```

**Why**: Enables code isolation while sharing storage

### Shared Storage
Storage that all facets can access.

**Example**:
```solidity
// DiamondLib storage - all facets can access
mapping(bytes4 selector => address facet) selectorToFacet;

// OwnableLib storage - all facets can call onlyOwner
address owner;

// Custom facet storage - if using ERC-7201
mapping(address => uint256) balances;
```

---

## Initialization & Lifecycle

### Initialization
Process of setting up the Diamond when it's first deployed.

**Why special for Diamond**:
- Constructors run on facet deployment, not Diamond deployment
- Initialization must run in Diamond's context via delegatecall
- Must be atomic (all succeed or all fail)

**Process**:
1. Deploy Diamond (empty, no functions yet)
2. Call `initialize(cuts, initContract, initData)`
3. Facets are added via diamond cuts
4. Initialization contract runs (sets owner, etc.)
5. Diamond is ready

### Initializer Contract
A temporary contract that runs during Diamond initialization.

**Purpose**: Set up initial state (owner, roles, balances, etc.)

**Example**: `DiamondInit.sol`
```solidity
function init() external {
    OwnableLib.initializeOwner(msg.sender);
    DiamondLib.registerInterface();
}
```

**Execution**: Runs via delegatecall in Diamond's context

### Reinitialization
Updating initialization state without resetting everything.

**Use case**: Upgrade with new state variables

**Protection**: Version tracking prevents accidental reinitialization
- v1 → v2 (success)
- v2 → v2 (failure: already at this version)
- v2 → v1 (failure: cannot go backward)

### Initialization Guard
Mechanism preventing reentrancy during initialization.

**Implementation**:
```solidity
// Flag: 0 = not init, 1 = currently initializing, 2 = done
if (isInitializing) revert InvalidInitialization();
```

**Prevents**: Accidentally calling initialization again during initialization

---

## Access Control

### Owner
The single address that can execute privileged operations.

**Owner can**:
- Call `diamondCut()` to modify facets
- Transfer ownership
- Call any public/external function (through facets)

**Owner cannot** (without code changes):
- Create restricted functions accessible only to certain addresses
- Time-delay upgrades
- Pause the contract
- Create emergency escape hatches

### onlyOwner
Modifier that restricts functions to owner.

```solidity
modifier onlyOwner() {
    OwnableLib.checkOwner();
    _;
}
```

**Use**: Critical functions should check `onlyOwner`

### Ownership Transfer
Process of changing the owner.

**Single-step** (dangerous):
```solidity
owner = newOwner;  // newOwner immediately becomes owner
```

**Two-step** (safer):
1. Current owner: `requestOwnershipHandover(newOwner)`
2. New owner waits to verify access
3. Current owner: `completeOwnershipHandover(newOwner)`

**Benefits**: Prevents transfer to wrong address

---

## Operations & Events

### DiamondCut Event
Emitted when facets are modified.

```solidity
event DiamondCut(
    FacetCut[] diamondCut,
    address init,
    bytes data
);
```

**Contains**:
- Array of operations (add/replace/remove)
- Initialization contract address (if any)
- Initialization calldata (if any)

**Use**: Track all Diamond composition changes

### Initialized Event
Emitted when initialization completes.

```solidity
event Initialized(uint64 version);
```

**Contains**: Version number of completed initialization

**Use**: Confirm Diamond initialization state

### OwnershipTransferred Event
Emitted when ownership changes.

```solidity
event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);
```

**Standard**: EIP-173 compatible

**Use**: Track ownership changes for security monitoring

---

## Advanced Concepts

### Immutable Function
A function that cannot be removed from the Diamond.

**Implementation**: Check if selector maps to Diamond contract itself
```solidity
if (facetAddress == address(this)) {
    revert CannotRemoveImmutableFunction();
}
```

**Use**: Prevent accidental removal of critical functions

### Selector Collision
When two different functions have the same selector (extremely rare).

**Probability**: ~1 in 2^32 for random functions

**Prevention**: Test function names, use standard library functions

**Resolution**: Rename conflicting function to change its selector

### Diamond Fragmentation
Over time, diamond cuts may create unused selectors or facets.

**Example**:
- Add 100 selectors from FacetA
- Replace 50 with FacetB
- Remove 30
- Result: FacetA still deployed but unused

**Cleanup**: Deploy new Diamond with only active facets

### Zero Address Check
Preventing facets from being the Diamond itself.

```solidity
if (facetAddress == address(this)) {
    revert CannotAddThisAddress();
}
```

**Why**: Would create delegatecall loop

---

## Testing & Verification

### Loupe Function Testing
Verify Diamond composition using loupe functions.

```solidity
// Verify facet was added
Facet[] memory facets = diamond.facets();
assertTrue(facets.length == 2);

// Verify selector routing
assertEq(diamond.facetAddress(selector), expectedFacet);

// Verify all selectors
bytes4[] memory selectors = diamond.facetFunctionSelectors(facet);
assertEq(selectors.length, expectedCount);
```

### Selector Verification
Ensure correct function selectors for cuts.

```solidity
bytes4 selector = bytes4(keccak256("myFunction(uint256)"));
// Verify selector is correct before cutting
```

### Storage Layout Testing
Verify ERC-7201 storage doesn't conflict.

```solidity
// Test that storage slots are unique
assertNotEqual(DIAMOND_STORAGE_LOCATION, CUSTOM_STORAGE_LOCATION);
```

### Access Control Testing
Verify onlyOwner restrictions work.

```solidity
// Should succeed (owner)
diamond.diamondCut(cuts, address(0), "");

// Should fail (non-owner)
vm.prank(nonOwner);
vm.expectRevert();
diamond.diamondCut(cuts, address(0), "");
```

---

## Common Patterns & Anti-Patterns

### Pattern: Facet Grouping
Group related functions together.

**Good**: All ERC20 functions in one facet
**Bad**: Random functions in each facet (hard to reason about)

### Pattern: Clean Upgrades
When replacing facet, document what changed.

**Good**: Deploy V2, track breaking changes, communicate clearly
**Bad**: Deploy V2 with undocumented behavior changes

### Anti-Pattern: Storage Conflicts
Different facets writing to same storage location.

**Problem**: Functions corrupt each other's state
**Solution**: Use ERC-7201 namespacing

### Anti-Pattern: Delegatecall Loops
Facet calls Diamond which calls facet.

**Problem**: Infinite loops, confusing control flow
**Solution**: Facets call libraries directly, not Diamond

### Anti-Pattern: Forgotten Facets
Deploy facet, forget to add to Diamond.

**Problem**: Facet code never executes
**Solution**: Verify `facetAddress(selector)` after cuts

---

## Troubleshooting

### "Function not found" Error
Function selector doesn't route to any facet.

**Causes**:
- Selector not added via diamond cut
- Selector misspelled
- Facet not actually added

**Fix**: Use loupe to verify `facetAddress(selector)` returns non-zero

### "Invalid initialization" Error
Attempt to reinitialize to same or lower version.

**Cause**: Already initialized and version unchanged

**Fix**: Increment version number for reinitializations

### "Cannot add function to diamond that already exists" Error
Selector already has a mapping.

**Cause**: Function was previously added or Cut is incomplete

**Fix**: Use `Replace` operation instead of `Add`, or verify prior cuts

### "No bytecode at address" Error
Trying to add facet that has no code.

**Cause**: Address provided is not a deployed contract

**Fix**: Verify facet was deployed to correct address

---

## References

- **EIP-2535**: [Diamond Standard Specification](https://eips.ethereum.org/EIPS/eip-2535)
- **ERC-7201**: [Namespaced Storage Layout](https://eips.ethereum.org/EIPS/eip-7201)
- **EIP-165**: [Interface Detection Standard](https://eips.ethereum.org/EIPS/eip-165)
- **EIP-173**: [Contract Ownership Standard](https://eips.ethereum.org/EIPS/eip-173)

---

**End of Glossary**
