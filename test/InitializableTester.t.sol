// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {ReinitializableDiamond} from "@diamond-test/mocks/ReinitializableDiamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {OwnableInit} from "@diamond/initializers/OwnableInit.sol";
import {ContextLib} from "@diamond/libraries/ContextLib.sol";
import {FacetCut, FacetCutAction} from "@diamond/libraries/DiamondLib.sol";
import {Initialized, InvalidInitialization} from "@diamond/libraries/InitializableLib.sol";

/// @title InitializableTester
/// @notice Tests for the initializable Diamond pattern
contract InitializableTester is GetSelectors {
    ReinitializableDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnableRolesFacet ownableRolesFacet;
    MultiInit multiInit;
    OwnableInit ownableInit;
    ERC165Init erc165Init;

    FacetCut[] cuts;

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownableRolesFacet = new OwnableRolesFacet();

        // Deploy initializers
        multiInit = new MultiInit();
        ownableInit = new OwnableInit();
        erc165Init = new ERC165Init();

        // Build facet cuts
        cuts.push(
            FacetCut({
                facetAddress: address(diamondCutFacet),
                action: FacetCutAction.Add,
                functionSelectors: _getSelectors("DiamondCutFacet")
            })
        );
        cuts.push(
            FacetCut({
                facetAddress: address(diamondLoupeFacet),
                action: FacetCutAction.Add,
                functionSelectors: _getSelectors("DiamondLoupeFacet")
            })
        );
        cuts.push(
            FacetCut({
                facetAddress: address(ownableRolesFacet),
                action: FacetCutAction.Add,
                functionSelectors: _getSelectors("OwnableRolesFacet")
            })
        );

        // Deploy diamond (uninitialized)
        diamond = new ReinitializableDiamond();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    INITIALIZATION TESTS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Diamond starts uninitialized with version 0
    function testVersionIsZeroBeforeInit() public view {
        assertEq(diamond.getInitializedVersion(), 0);
    }

    /// @notice Diamond is not in initializing state before init
    function testNotInitializingBeforeInit() public view {
        assertFalse(diamond.isInitializing());
    }

    /// @notice Initialize sets version to 1 and emits Initialized event
    function testInitializeSetsVersionAndEmitsEvent() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));

        vm.expectEmit(false, false, false, true);
        emit Initialized(1);

        diamond.initialize(facetCuts, init, initCalldata);

        assertEq(diamond.getInitializedVersion(), 1);
        assertFalse(diamond.isInitializing());
    }

    /// @notice Second call to initialize reverts with InvalidInitialization
    function testCannotInitializeTwice() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        // Second initialization should revert
        FacetCut[] memory emptyCuts = new FacetCut[](0);
        vm.expectRevert(InvalidInitialization.selector);
        diamond.initialize(emptyCuts, address(0), "");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   REINITIALIZATION TESTS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Reinitialize to version 2 after initial initialization
    function testReinitializeToVersion2() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        FacetCut[] memory emptyCuts = new FacetCut[](0);

        vm.expectEmit(false, false, false, true);
        emit Initialized(2);

        diamond.reinitialize(emptyCuts, address(0), "", 2);

        assertEq(diamond.getInitializedVersion(), 2);
    }

    /// @notice Cannot reinitialize with same version
    function testCannotReinitializeWithSameVersion() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        FacetCut[] memory emptyCuts = new FacetCut[](0);
        vm.expectRevert(InvalidInitialization.selector);
        diamond.reinitialize(emptyCuts, address(0), "", 1);
    }

    /// @notice Cannot reinitialize with lower version
    function testCannotReinitializeWithLowerVersion() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        FacetCut[] memory emptyCuts = new FacetCut[](0);
        diamond.reinitialize(emptyCuts, address(0), "", 2);

        vm.expectRevert(InvalidInitialization.selector);
        diamond.reinitialize(emptyCuts, address(0), "", 1);
    }

    /// @notice Version increments correctly through multiple reinitializations
    function testSequentialReinitializations() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);
        assertEq(diamond.getInitializedVersion(), 1);

        FacetCut[] memory emptyCuts = new FacetCut[](0);
        diamond.reinitialize(emptyCuts, address(0), "", 2);
        assertEq(diamond.getInitializedVersion(), 2);

        diamond.reinitialize(emptyCuts, address(0), "", 5);
        assertEq(diamond.getInitializedVersion(), 5);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  DISABLE INITIALIZERS TESTS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice disableInitializers prevents future initialization
    function testDisableInitializersPreventsInit() public {
        diamond.disableInitializers();

        FacetCut[] memory emptyCuts = new FacetCut[](0);
        vm.expectRevert(InvalidInitialization.selector);
        diamond.initialize(emptyCuts, address(0), "");
    }

    /// @notice disableInitializers prevents future reinitialization
    function testDisableInitializersPreventsReinit() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        diamond.disableInitializers();

        FacetCut[] memory emptyCuts = new FacetCut[](0);
        vm.expectRevert(InvalidInitialization.selector);
        diamond.reinitialize(emptyCuts, address(0), "", 2);
    }

    /// @notice disableInitializers sets version to max uint64
    function testDisableInitializersSetsMaxVersion() public {
        diamond.disableInitializers();
        assertEq(diamond.getInitializedVersion(), type(uint64).max);
    }

    /// @notice disableInitializers emits Initialized with max uint64
    function testDisableInitializersEmitsEvent() public {
        vm.expectEmit(false, false, false, true);
        emit Initialized(type(uint64).max);

        diamond.disableInitializers();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     MULTI-INIT TESTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice MultiInit correctly initializes owner and ERC165 through initialize
    function testMultiInitSetsOwnerAndInterfaces() public {
        (FacetCut[] memory facetCuts, address init, bytes memory initCalldata) = _buildInitArgs(address(this));
        diamond.initialize(facetCuts, init, initCalldata);

        // Verify owner was set
        OwnableRolesFacet ownable = OwnableRolesFacet(address(diamond));
        assertEq(ownable.owner(), address(this));

        // Verify ERC165 interfaces were registered
        DiamondLoupeFacet loupe = DiamondLoupeFacet(address(diamond));
        assertTrue(loupe.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(loupe.supportsInterface(0x7f5828d0)); // ERC173
        assertTrue(loupe.supportsInterface(0x1f931c1c)); // IDiamondCut
        assertTrue(loupe.supportsInterface(0x48e2b093)); // IDiamondLoupe
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        HELPERS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _buildInitArgs(address _owner)
        internal
        view
        returns (FacetCut[] memory facetCuts_, address init_, bytes memory initCalldata_)
    {
        facetCuts_ = new FacetCut[](cuts.length);
        for (uint256 i; i < cuts.length; ++i) {
            facetCuts_[i] = cuts[i];
        }

        address[] memory initAddresses = new address[](2);
        bytes[] memory initData = new bytes[](2);

        initAddresses[0] = address(ownableInit);
        initData[0] = abi.encodeWithSignature("initOwner(address)", _owner);

        initAddresses[1] = address(erc165Init);
        initData[1] = abi.encodeWithSignature("initERC165()");

        init_ = address(multiInit);
        initCalldata_ = abi.encodeWithSignature("multiInit(address[],bytes[])", initAddresses, initData);
    }
}
