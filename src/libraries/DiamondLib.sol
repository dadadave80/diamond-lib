// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT EVENT
//////////////////////////////////////////////////////////////////////////*//

/// @notice Emitted when a diamond cut (facet add/replace/remove) is executed.
/// @dev Logged after executing `diamondCut` with its associated initializer.
/// @param diamondCut The array of facet cuts specifying facet addresses, actions, and function selectors.
/// @param init The address of the contract or facet to delegatecall for initialization.
/// @param data The calldata passed to the `init` address for initialization.
event DiamondCut(FacetCut[] diamondCut, address init, bytes data);

//*//////////////////////////////////////////////////////////////////////////
//                           DIAMOND LIBRARY ERRORS
//////////////////////////////////////////////////////////////////////////*//

/// @notice Thrown when attempting a diamond cut with no function selectors specified to add
error NoSelectorsGivenToAdd();

/// @notice Thrown when no function selectors are provided for a given facet in a cut
/// @param facetAddress The facet contract address for which selectors were expected
error NoSelectorsProvidedForFacetCut(address facetAddress);

/// @notice Thrown when trying to add selectors under the zero address (invalid facet)
/// @param selectors The selectors attempted to be added
error CannotAddSelectorsToZeroAddress(bytes4[] selectors);

/// @notice Thrown when verifying a facet contract but finding no deployed bytecode
/// @param contractAddress The address checked for deployed bytecode
error NoBytecodeAtAddress(address contractAddress);

/// @notice Thrown when adding a function selector that already exists in the diamond
/// @param selector The selector that is already present
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 selector);

/// @notice Thrown when replacing a function with the same implementation from the same facet
/// @param selector The selector that would result in a no-op replace
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 selector);

/// @notice Thrown when removing a facet but the facet address provided is non-zero
/// @param facetAddress The address that should have been zero for removals
error RemoveFacetAddressMustBeZeroAddress(address facetAddress);

/// @notice Thrown when attempting to remove a function selector that isn’t in the diamond
/// @param selector The selector that could not be found
error CannotRemoveFunctionThatDoesNotExist(bytes4 selector);

/// @notice Thrown when attempting to add a function defined directly in the diamond contract
error CannotAddImmutableFunction();

/// @notice Thrown when attempting to remove an immutable function
/// @param selector The selector of the immutable function
error CannotRemoveImmutableFunction(bytes4 selector);

/// @notice Thrown when the initialization call following a diamond cut reverts
/// @param initAddress The address of the init contract that reverted
/// @param data The calldata passed to the init contract
error InitializeDiamondCutReverted(address initAddress, bytes data);

/// @notice Thrown when a called function selector does not map to any facet
/// @param functionSelector The selector of the function attempted
error FunctionDoesNotExist(bytes4 functionSelector);

//*//////////////////////////////////////////////////////////////////////////
//                           DIAMOND STORAGE TYPES
//////////////////////////////////////////////////////////////////////////*//

/// @dev This struct is used to store the facet address and position of the
///      function selector in the facetToSelectorsAndPosition.functionSelectors
///      array.
struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition;
}

/// @dev This struct is used to store the function selectors and position of
///      the facet address in the facetAddresses array.
struct FacetFunctionSelectorsAndPosition {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition;
}

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT TYPES
//////////////////////////////////////////////////////////////////////////*//

/// @notice Actions that can be performed on a facet during a diamond cut
/// @dev `Add` will add new function selectors, `Replace` will swap existing
///       selectors to a new facet, `Remove` will delete selectors
enum FacetCutAction {
    Add,
    Replace,
    Remove
}

/// @notice Defines an operation (add/replace/remove) to perform on a facet
/// @param facetAddress The address of the facet contract to operate on
/// @param action The action to perform (Add, Replace, Remove)
/// @param functionSelectors List of function selectors to apply the action to
struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

/// @notice Struct representing a facet in a diamond contract.
/// @dev Used for introspection of facet data through loupe functions.
/// @param facetAddress The address of the facet contract.
/// @param functionSelectors The list of function selectors provided by this facet.
struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

//*//////////////////////////////////////////////////////////////////////////
//                              DIAMOND STORAGE
//////////////////////////////////////////////////////////////////////////*//

// keccak256(abi.encode(uint256(keccak256("diamond.lib.storage")) - 1)) & ~bytes32(uint256(0xff));
bytes32 constant DIAMOND_STORAGE_LOCATION = 0x6d5a93fec60e12d72b781fe97b2b5406e385b9eaa23d3ec2fbfa067f9d0dc000;

/// @notice Storage structure for managing facets and interface support in a Diamond (EIP-2535) proxy
/// @dev Tracks function selector mappings, facet lists, and ERC-165 interface support
/// @custom:storage-location erc7201:diamond.lib.storage
struct DiamondStorage {
    /// @notice Maps each function selector to the facet address and selector’s position in that facet
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    /// @notice Maps each facet address to its function selectors and the facet’s position in the global list
    mapping(address => FacetFunctionSelectorsAndPosition) facetToSelectorsAndPosition;
    /// @notice Array of all facet addresses registered in the diamond
    address[] facetAddresses;
    /// @notice Tracks which interface IDs (ERC-165) are supported by the diamond
    mapping(bytes4 => bool) supportedInterfaces;
}

/// @title DiamondLib
/// @notice Internal library providing core functionality for ERC-2535 Diamond proxy management.
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol)
///
/// @dev Defines the diamond storage layout and implements the `_diamondCut` operation and storage accessors
library DiamondLib {
    //*//////////////////////////////////////////////////////////////////////////
    //                              DIAMOND STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Get the diamond storage.
    function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
        assembly {
            ds_.slot := DIAMOND_STORAGE_LOCATION
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             DIAMOND FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Add/replace/remove any number of functions and optionally execute
    ///      a function with delegatecall.
    /// @param _facetCuts Contains the facet addresses, cut actions and function selectors.
    /// @param _init The address of the contract or facet to execute `data`.
    /// @param _calldata A function call, including function selector and arguments.
    function diamondCut(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 facetCutsLength = _facetCuts.length;
        for (uint256 i; i < facetCutsLength; ++i) {
            if (_facetCuts[i].action == FacetCutAction.Add) {
                addFunctions(ds, _facetCuts[i].facetAddress, _facetCuts[i].functionSelectors);
            } else if (_facetCuts[i].action == FacetCutAction.Replace) {
                replaceFunctions(ds, _facetCuts[i].facetAddress, _facetCuts[i].functionSelectors);
            } else {
                removeFunctions(ds, _facetCuts[i].facetAddress, _facetCuts[i].functionSelectors);
            }
        }

        initializeDiamondCut(_init, _calldata);
        emit DiamondCut(_facetCuts, _init, _calldata);
    }

    /// @dev Add functions to the diamond.
    /// @param _facetAddress The address of the facet to add functions to.
    /// @param _functionSelectors The function selectors to add to the facet.
    function addFunctions(DiamondStorage storage _ds, address _facetAddress, bytes4[] calldata _functionSelectors)
        internal
    {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        uint96 selectorPosition = uint96(facetToSelectors(_ds, _facetAddress).length);
        // Add new facet address if it does not exist
        if (selectorPosition == 0) addFacet(_ds, _facetAddress);
        for (uint256 i; i < functionSelectorsLength; ++i) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = selectorToFacet(_ds, selector);
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            addFunction(_ds, selector, selectorPosition, _facetAddress);
            ++selectorPosition;
        }
    }

    /// @dev Replace functions in the diamond.
    /// @param _facetAddress The address of the facet to replace functions from.
    /// @param _functionSelectors The function selectors to replace in the facet.
    function replaceFunctions(DiamondStorage storage _ds, address _facetAddress, bytes4[] calldata _functionSelectors)
        internal
    {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        uint96 selectorPosition = uint96(facetToSelectors(_ds, _facetAddress).length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) addFacet(_ds, _facetAddress);
        for (uint256 i; i < functionSelectorsLength; ++i) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = selectorToFacet(_ds, selector);
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            removeFunction(_ds, oldFacetAddress, selector);
            addFunction(_ds, selector, selectorPosition, _facetAddress);
            ++selectorPosition;
        }
    }

    /// @dev Remove functions from the diamond.
    /// @param _facetAddress The address of the facet to remove functions from.
    /// @param _functionSelectors The function selectors to remove from the facet.
    function removeFunctions(DiamondStorage storage _ds, address _facetAddress, bytes4[] calldata _functionSelectors)
        internal
    {
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) {
            revert NoSelectorsProvidedForFacetCut(_facetAddress);
        }
        for (uint256 i; i < functionSelectorsLength; ++i) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = selectorToFacet(_ds, selector);
            removeFunction(_ds, oldFacetAddress, selector);
        }
    }

    /// @dev Add a facet address to the diamond.
    /// @param _ds Diamond storage.
    /// @param _facetAddress The address of the facet to add.
    function addFacet(DiamondStorage storage _ds, address _facetAddress) internal {
        if (_facetAddress == address(this)) revert CannotAddImmutableFunction();
        _enforceHasContractCode(_facetAddress);
        _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition = _ds.facetAddresses.length;
        _ds.facetAddresses.push(_facetAddress);
    }

    /// @dev Add a function to the diamond.
    /// @param _ds Diamond storage.
    /// @param _selector The function selector to add.
    /// @param _selectorPosition The position of the function selector in the facetToSelectorsAndPosition.functionSelectors array.
    /// @param _facetAddress The address of the facet to add the function selector to.
    function addFunction(DiamondStorage storage _ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.push(_selector);
        _ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    /// @dev Remove a function from the diamond.
    /// @param _ds Diamond storage.
    /// @param _facetAddress The address of the facet to remove the function from.
    /// @param _selector The function selector to remove.
    function removeFunction(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) {
            revert CannotRemoveFunctionThatDoesNotExist(_selector);
        }
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) {
            revert CannotRemoveImmutableFunction(_selector);
        }
        // replace selector with last selector, then delete last selector
        uint96 selectorPosition = _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = facetToSelectors(_ds, _facetAddress).length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = facetToSelectors(_ds, _facetAddress)[lastSelectorPosition];
            _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = selectorPosition;
        }
        // delete the last selector
        _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.pop();
        delete _ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = facetToPosition(_ds, _facetAddress);
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _ds.facetAddresses[lastFacetAddressPosition];
                _ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                _ds.facetToSelectorsAndPosition[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _ds.facetAddresses.pop();
            delete _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function selectorToFacet(bytes4 _selector) internal view returns (address facet_) {
        facet_ = selectorToFacet(diamondStorage(), _selector);
        if (facet_ == address(0)) revert FunctionDoesNotExist(msg.sig);
    }

    function selectorToFacet(DiamondStorage storage _ds, bytes4 _selector) internal view returns (address) {
        return _ds.selectorToFacetAndPosition[_selector].facetAddress;
    }

    function facetToSelectors(DiamondStorage storage _ds, address _facetAddress)
        internal
        view
        returns (bytes4[] memory)
    {
        return _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors;
    }

    function facetToPosition(DiamondStorage storage _ds, address _facetAddress) internal view returns (uint256) {
        return _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                            DIAMOND INITIALIZER
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Initialize the diamond cut.
    /// @param _init The address of the contract or facet to execute `data`.
    /// @param _calldata A function call, including function selector and arguments.
    function initializeDiamondCut(address _init, bytes calldata _calldata) internal {
        if (_init == address(0)) return;
        _enforceHasContractCode(_init);
        (bool success, bytes memory err) = _init.delegatecall(_calldata);
        if (!success) {
            if (err.length > 0) {
                // bubble up error
                assembly ("memory-safe") {
                    let returndata_size := mload(err)
                    revert(add(32, err), returndata_size)
                }
            } else {
                revert InitializeDiamondCutReverted(_init, _calldata);
            }
        }
    }

    /// @dev Enforce that the contract has bytecode.
    /// @param _contract The address of the contract to check.
    function _enforceHasContractCode(address _contract) private view {
        if (_contract.code.length == 0) revert NoBytecodeAtAddress(_contract);
    }
}
