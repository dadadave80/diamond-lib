// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondArgs, DiamondStorage, FacetCut} from "@diamond-storage/DiamondStorage.sol";
import {FunctionDoesNotExist} from "@diamond-errors/DiamondErrors.sol";
import {LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⡤⣶⣾⠟⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠛⠛⠓⠶⠤⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢠⣴⠶⠛⠿⢿⣶⣿⡋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠓⠲⢦⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣴⡾⠋⠀⠀⢀⣴⠟⠁⠈⠛⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠲⢶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣠⣶⡿⠋⠀⠀⠀⣠⠟⠁⠀⠀⠀⣀⣨⣿⣶⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣰⣾⡿⠋⠀⠀⣀⣤⣾⣥⠶⠒⠚⠋⠉⠉⠁⠀⠘⣧⠈⠉⠛⠒⠶⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣝⠷⣤⡀⠀⠀⠀⠀⠀⠀⠀
⣿⡿⠒⠛⠋⢉⡽⠋⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣧⠀⠀⠀⠀⠀⠀⠉⠉⠛⠒⢶⣤⣤⣤⣤⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⠶⠛⠙⣟⠚⠻⢶⣄⠀⠀⠀⠀⠀
⢻⣷⡀⢀⣴⠏⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡆⠀⠀⠀⣀⣤⣤⠴⠖⠚⠋⠉⠛⢦⣄⡀⠀⠉⠉⠉⠉⠉⠉⠉⠉⣹⡿⠿⣥⡀⠀⠀⠀⠹⣆⠀⠀⠹⣧⡀⠀⠀⠀
⠈⢿⡹⣿⡁⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⡴⣿⣶⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⠀⠀⠀⠀⠀⢀⡾⠋⠀⠀⠈⠙⠳⣦⡀⠀⢻⡄⠀⠀⠹⣷⡀⠀⠀
⠀⠈⣷⣬⣿⣦⣄⠀⣿⠀⣀⣠⣤⡴⠖⠚⠋⠉⠁⠀⠀⡏⠈⢷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣦⡀⢀⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⢦⣷⡀⠀⠀⠹⣿⡄⠀
⠀⠀⠈⠻⣆⠉⠙⣿⡙⠻⢯⣀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⠀⠀⠙⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡿⡿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⢿⢦⣄⠀⠹⣿⣆
⠀⠀⠀⠀⠈⢷⣄⠀⠙⢷⣄⣉⡻⣶⣄⣀⠀⠀⠀⢀⣿⠀⠀⠀⠀⠀⠻⣦⡀⠀⠀⠀⠀⠀⠀⢀⣠⡴⠞⠉⠀⢸⡇⠀⠙⠳⣦⡀⠀⠀⠀⠀⠀⠀⠀⣾⠀⠈⣧⠈⠙⢦⣽⣼
⠀⠀⠀⠀⠀⠀⠙⢧⡄⠀⠻⣯⡉⠉⠉⠛⢿⣍⡉⠉⠙⠷⣤⣀⠀⠀⠀⠈⠻⣦⠀⠀⣀⣤⠶⠋⠁⠀⠀⠀⠀⢸⠃⠀⠀⠀⠀⠙⠷⣤⡀⠀⠀⠀⣼⠃⠀⠀⠘⣦⠀⢀⣬⡿
⠀⠀⠀⠀⠀⠀⠀⠀⠻⣦⡀⢹⣷⣄⠀⠀⠀⠈⠙⢶⡶⠶⠶⠯⣭⣛⣓⡲⠶⠾⠷⠿⣭⣀⣀⠀⠀⠀⠀⠀⣀⣾⠀⠀⠀⠀⠀⠀⠀⠈⠛⢶⣄⣰⠏⠀⠀⢀⣠⡿⢟⡿⠋⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⢻⣟⢷⡄⠀⠀⠀⠈⢷⠀⠀⠀⠀⠀⠈⠉⠓⢶⣦⠴⠶⠾⠭⣭⣍⣉⣉⠉⠉⠉⠙⠳⢶⣤⣄⣤⡴⠶⠖⠛⠋⣙⣿⠷⠿⠿⣧⣶⠟⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣽⣆⠻⣦⡀⠀⠀⠘⣇⠀⠀⠀⠀⠀⠀⠀⣼⣷⠀⠀⠀⠀⠀⠀⠈⠉⢛⣶⠶⠛⠉⠉⠁⠀⠉⠙⣳⣶⠞⠋⠉⠀⣀⡶⠾⠋⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣎⠌⢳⣄⠀⠀⢹⣆⠀⠀⠀⠀⠀⣼⠃⣿⠀⠀⠀⠀⠀⠀⠀⣠⠟⠁⠀⠀⠀⠀⠀⣠⣴⡿⠛⠁⢀⣤⠶⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⡀⠙⣧⡀⠀⢻⡄⠀⠀⠀⣸⠇⠀⣿⠀⠀⠀⠀⠀⢠⡾⠃⠀⠀⠀⢀⣤⠾⣫⡿⢋⣀⡴⠞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣆⠈⠻⣆⠈⣷⠀⠀⣰⡏⠀⠀⢻⠀⠀⠀⢀⣴⠏⠀⠀⣀⣴⠞⠋⣠⣾⣿⠾⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣄⠘⢷⡼⣇⢀⡟⠀⠀⠀⢸⠀⠀⣠⠟⠁⣠⡴⠞⠉⢀⣠⡾⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣦⡀⠹⣿⡾⠁⠀⠀⠀⢸⣀⣾⣣⠶⠛⠁⣀⣤⠾⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⠈⢿⡀⠀⠀⢀⣼⠟⠋⢀⣠⠴⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠷⣜⣧⠀⣠⠟⣁⣴⠞⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣾⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
*/

/// @title Diamond
/// @notice Implements EIP-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/Diamond.sol)
///
/// @dev Uses LibDiamond for facet management and LibOwnableRoles for ownership initialization
abstract contract Diamond {
    /// @notice Initializes the Diamond proxy with the provided facets and initialization parameters
    /// @param _facetCuts Array of FacetCut structs defining facet addresses, corresponding function selectors, and actions (Add, Replace, Remove)
    /// @param _args Struct containing the initial owner address, optional init contract address, and init calldata
        LibOwnableRoles._initializeOwner(_args.owner);
        LibDiamond._diamondCut(_diamondCut, _args.init, _args.initData);
    }

    /// @notice Receive function to accept plain Ether transfers
    /// @dev Allows contract to receive Ether without data
    receive() external payable {}

    /// @notice Fallback function that delegates calls to the appropriate facet based on function selector
    /// @dev Reads the facet address from diamond storage and performs a delegatecall; reverts if selector is not found
    fallback() external payable {
        // Lookup facet for function selector
        address facet = LibDiamond._diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) revert FunctionDoesNotExist(msg.sig);

        assembly {
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())

            // Delegate call to facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            // Copy returned data
            returndatacopy(0, 0, returndatasize())

            // Revert or return based on the result
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
