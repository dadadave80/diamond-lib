# Diamond Library Developer Guide

A practical guide for developers building with the Diamond library.

---

## Quick Start

### 1. Install the Library

```bash
forge install dadadave80/diamond-lib
```

### 2. Basic Diamond Setup

```bash
forge script script/DeployDiamond.s.sol:DeployDiamond \
--rpc-url <YOUR-RPC-URL> \
--private-key <YOUR-PRIVATE-KEY> \
--broadcast
```

---

## Common Tasks

### Task 1: Create a Custom Facet

```solidity
import {OwnableLib} from "@diamond/libraries/OwnableLib.sol";

contract TokenFacet {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    // Use this storage layout to avoid conflicts
    // Make sure to use ERC-7201 namespace if multiple facets use token storage
    
    modifier onlyOwner() {
        OwnableLib.checkOwner();
        _;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        // Implementation
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        // Implementation
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function burn(uint256 amount) external onlyOwner {
        // Only owner can call
    }
}
```

### Task 2: Add a Custom Facet to Diamond

```solidity
contract AddFacetScript {
    function addTokenFacet(address diamond) external {
        // 1. Deploy new facet
        TokenFacet tokenFacet = new TokenFacet();
        
        // 2. Get selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TokenFacet.transfer.selector;
        selectors[1] = TokenFacet.approve.selector;
        selectors[2] = TokenFacet.burn.selector;
        
        // 3. Create cut
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: address(tokenFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        // 4. Execute cut (caller must be owner)
        IDiamondCut(diamond).diamondCut(cuts, address(0), "");
    }
}
```

### Task 3: Verify Diamond Composition

```solidity
contract VerifyDiamond {
    function verify(address diamond) external view {
        IDiamondLoupe loupe = IDiamondLoupe(diamond);
        
        // Get all facets
        Facet[] memory facets = loupe.facets();
        console.log("Total facets:", facets.length);
        
        // Verify specific selectors
        bytes4 facetsSelector = bytes4(keccak256("facets()"));
        address facetAddr = loupe.facetAddress(facetsSelector);
        
        if (facetAddr != address(0)) {
            console.log("facets() routed to:", facetAddr);
        } else {
            console.log("facets() not found in Diamond");
        }
    }
}
```

### Task 4: Replace a Facet Implementation

```solidity
contract UpdateFacet {
    function updateTokenFacet(address diamond, address newImplementation) external {
        // 1. Get existing selectors
        IDiamondLoupe loupe = IDiamondLoupe(diamond);
        bytes4[] memory selectors = loupe.facetFunctionSelectors(
            loupe.facetAddress(TokenFacet.transfer.selector)
        );
        
        // 2. Create replacement cut
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: newImplementation,
            action: FacetCutAction.Replace,
            functionSelectors: selectors
        });
        
        // 3. Execute cut with optional initialization
        IDiamondCut(diamond).diamondCut(
            cuts,
            address(migrationInit),
            abi.encodeCall(MigrationInit.migrate, ())
        );
    }
}
```

### Task 5: Remove Deprecated Functions

```solidity
contract RemoveFunctions {
    function removeDeprecatedFunctions(address diamond) external {
        // 1. Identify selectors to remove
        bytes4[] memory selectorsToRemove = new bytes4[](2);
        selectorsToRemove[0] = bytes4(keccak256("legacyFunction1()"));
        selectorsToRemove[1] = bytes4(keccak256("legacyFunction2()"));
        
        // 2. Create removal cut
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: address(0),  // Must be zero for removal
            action: FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        });
        
        // 3. Execute removal
        IDiamondCut(diamond).diamondCut(cuts, address(0), "");
    }
}
```

---

## Storage Management

### Using ERC-7201 Storage in Custom Facets

```solidity
// 1. Define storage library
library MyTokenStorage {
    // Compute with: keccak256(abi.encode(uint256(keccak256("my.token.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant STORAGE_LOCATION = 0x1234567890abcdef...;
    
    struct Data {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
    }
    
    function getStorage() internal pure returns (Data storage s) {
        assembly {
            s.slot := STORAGE_LOCATION
        }
    }
}

// 2. Use in facet
contract MyTokenFacet {
    using MyTokenStorage for MyTokenStorage.Data;
    
    function transfer(address to, uint256 amount) external {
        MyTokenStorage.Data storage s = MyTokenStorage.getStorage();
        s.balances[msg.sender] -= amount;
        s.balances[to] += amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return MyTokenStorage.getStorage().balances[account];
    }
}
```

### Avoid Storage Conflicts

**DO:**
```solidity
// Use ERC-7201 namespaces
bytes32 constant STORAGE_LOCATION = keccak256(abi.encode(...));
```

**DON'T:**
```solidity
// Don't use hardcoded slots
uint256 constant MY_STORAGE_SLOT = 1;
```

**DON'T:**
```solidity
// Don't share storage slots between facets
bytes32 constant STORAGE_LOCATION_1 = keccak256(abi.encode("1"));
bytes32 constant STORAGE_LOCATION_2 = keccak256(abi.encode("1"));
// (unless explicitly coordinated)
```

---

## Testing Patterns

### Test Diamond Initialization

```solidity
contract DiamondTest is Test {
    Diamond diamond;
    
    function setUp() public {
        // Deploy and initialize
        diamond = new Diamond();
        // ... initialization code ...
    }
    
    function test_DiamondInitialized() public {
        // Verify core facets are present
        IDiamondLoupe loupe = IDiamondLoupe(address(diamond));
        Facet[] memory facets = loupe.facets();
        
        assertGt(facets.length, 0);
    }
}
```

### Test Facet Addition

```solidity
function test_AddCustomFacet() public {
    // Deploy new facet
    CustomFacet facet = new CustomFacet();
    
    // Prepare cut
    bytes4[] memory selectors = new bytes4[](1);
    selectors[0] = CustomFacet.myFunction.selector;
    
    FacetCut[] memory cuts = new FacetCut[](1);
    cuts[0] = FacetCut({
        facetAddress: address(facet),
        action: FacetCutAction.Add,
        functionSelectors: selectors
    });
    
    // Execute cut
    IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
    
    // Verify
    IDiamondLoupe loupe = IDiamondLoupe(address(diamond));
    assertEq(loupe.facetAddress(selectors[0]), address(facet));
}
```

### Test Access Control

```solidity
function test_OnlyOwnerCanCut() public {
    // Non-owner attempt should fail
    vm.prank(nonOwner);
    vm.expectRevert();
    IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
}
```

---

## Ownership Transfer

### Request & Complete Two-Step Transfer

```solidity
function transferOwnershipSafely(address diamond, address newOwner) external {
    IOwnableFacet ownable = IOwnableFacet(diamond);
    
    // Step 1: Current owner requests handover
    ownable.requestOwnershipHandover(newOwner);
    
    // Step 2: New owner accepts (in separate transaction/call)
    vm.prank(newOwner);  // If testing, switch to new owner
    ownable.completeOwnershipHandover(newOwner);
}
```

### Handle Ownership Expiry

```solidity
function cancelOwnershipIfNeeded(address diamond) external {
    IOwnableFacet ownable = IOwnableFacet(diamond);
    
    // If less than 48 hours have passed, owner can cancel
    ownable.cancelOwnershipHandover();
}
```

---

## Best Practices

### 1. Always Test Facet Cuts in Staging

```solidity
// Test on local/staging fork before mainnet
function testCutOnStaging() public {
    // Propose cut
    // Simulate execution
    // Verify results
    // Check storage state
}
```

### 2. Verify Bytecode Before Adding Facets

```solidity
function verifyFacetCode(address facet) external view {
    // Ensure facet has code
    require(facet.code.length > 0, "No bytecode");
    
    // Optionally: verify source code matches
}
```

### 3. Document Selector Mappings

```solidity
// Keep a registry of selectors
contract SelectorRegistry {
    mapping(bytes4 => string) selectorToFunction;
    
    function register(bytes4 selector, string memory name) external onlyOwner {
        selectorToFunction[selector] = name;
    }
}
```

### 4. Monitor DiamondCut Events

```solidity
// Listen for DiamondCut events in monitoring system
event DiamondCut(
    FacetCut[] indexed diamondCut,
    address indexed init,
    bytes data
);

// Parse cuts to track:
// - Which facets were added/replaced/removed
// - What selectors changed
// - When upgrades occurred
```

### 5. Use Initialization Versions for Staged Upgrades

```solidity
contract V2Init {
    function init() external reinitializer(2) {
        // Runs only once on upgrade to version 2
        // Cannot run again
        // Safely adds new state
    }
}
```

---

## Troubleshooting

### Error: "Function does not exist"

**Cause**: Selector not routed to any facet

**Solution**:
```solidity
// Check if selector is registered
IDiamondLoupe loupe = IDiamondLoupe(diamond);
address facet = loupe.facetAddress(selector);
require(facet != address(0), "Selector not found");
```

### Error: "Cannot add function that already exists"

**Cause**: Using `Add` when selector already exists

**Solution**:
```solidity
// Use `Replace` instead if updating existing function
// Or remove first, then add
```

### Error: "Cannot remove function that doesn't exist"

**Cause**: Selector doesn't map to any facet

**Solution**:
```solidity
// Verify selector before removing
// Use loupe to check
```

### Storage Corruption

**Cause**: Multiple facets writing to same storage location

**Solution**:
```solidity
// Use ERC-7201 namespacing for all custom storage
// Coordinate storage layout with team
// Document all storage locations
```

---

## Performance Optimization

### Selector Lookup Performance

The diamond fallback is optimized for speed:

```solidity
fallback() external payable {
    address implementation = DiamondLib.selectorToFacet(msg.sig);
    assembly {
        // Optimized delegatecall
    }
}
```

**Gas cost**: ~3000 gas for fallback routing + facet execution

### Storage Access

Use ERC-7201 to keep storage accesses efficient:

```solidity
// O(1) storage access with proper namespacing
function erc165Storage() internal pure returns (ERC165Storage storage es_) {
    assembly {
        es_.slot := ERC165_STORAGE_LOCATION
    }
}
```

---

## Resources

- **SPECIFICATION.md**: Full architecture documentation
- **GLOSSARY.md**: Terminology reference
- **CONTRIBUTING.md**: Contributing guidelines
- **SECURITY.md**: Security policy

---

**End of Developer Guide**
