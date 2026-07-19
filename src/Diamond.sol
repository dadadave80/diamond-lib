// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondLib} from "@diamond/libraries/DiamondLib.sol";

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⡤⣶⣾⠟⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠛⠛⠓⠶⠤⣤⣀⡀
⠀⠀⠀⠀⠀⠀⠀⢠⣴⠶⠛⠿⢿⣶⣿⡋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠓⠲⢦⣤⣀⣀
⠀⠀⠀⠀⢀⣴⡾⠋⠀⠀⢀⣴⠟⠁⠈⠛⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠲⢶⣄
⠀⠀⣠⣶⡿⠋⠀⠀⠀⣠⠟⠁⠀⠀⠀⣀⣨⣿⣶⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣦⡀
⣰⣾⡿⠋⠀⠀⣀⣤⣾⣥⠶⠒⠚⠋⠉⠉⠁⠀⠘⣧⠈⠉⠛⠒⠶⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣝⠷⣤⡀
⣿⡿⠒⠛⠋⢉⡽⠋⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣧⠀⠀⠀⠀⠀⠀⠉⠉⠛⠒⢶⣤⣤⣤⣤⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⠶⠛⠙⣟⠚⠻⢶⣄
⢻⣷⡀⢀⣴⠏⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡆⠀⠀⠀⣀⣤⣤⠴⠖⠚⠋⠉⠛⢦⣄⡀⠀⠉⠉⠉⠉⠉⠉⠉⠉⣹⡿⠿⣥⡀⠀⠀⠀⠹⣆⠀⠀⠹⣧⡀
⠈⢿⡹⣿⡁⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⡴⣿⣶⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⠀⠀⠀⠀⠀⢀⡾⠋⠀⠀⠈⠙⠳⣦⡀⠀⢻⡄⠀⠀⠹⣷⡀
⠀⠈⣷⣬⣿⣦⣄⠀⣿⠀⣀⣠⣤⡴⠖⠚⠋⠉⠁⠀⠀⡏⠈⢷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣦⡀⢀⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⢦⣷⡀⠀⠀⠹⣿⡄
⠀⠀⠈⠻⣆⠉⠙⣿⡙⠻⢯⣀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⠀⠀⠙⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡿⡿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⢿⢦⣄⠀⠹⣿⣆
⠀⠀⠀⠀⠈⢷⣄⠀⠙⢷⣄⣉⡻⣶⣄⣀⠀⠀⠀⢀⣿⠀⠀⠀⠀⠀⠻⣦⡀⠀⠀⠀⠀⠀⠀⢀⣠⡴⠞⠉⠀⢸⡇⠀⠙⠳⣦⡀⠀⠀⠀⠀⠀⠀⠀⣾⠀⠈⣧⠈⠙⢦⣽⣼
⠀⠀⠀⠀⠀⠀⠙⢧⡄⠀⠻⣯⡉⠉⠉⠛⢿⣍⡉⠉⠙⠷⣤⣀⠀⠀⠀⠈⠻⣦⠀⠀⣀⣤⠶⠋⠁⠀⠀⠀⠀⢸⠃⠀⠀⠀⠀⠙⠷⣤⡀⠀⠀⠀⣼⠃⠀⠀⠘⣦⠀⢀⣬⡿
⠀⠀⠀⠀⠀⠀⠀⠀⠻⣦⡀⢹⣷⣄⠀⠀⠀⠈⠙⢶⡶⠶⠶⠯⣭⣛⣓⡲⠶⠾⠷⠿⣭⣀⣀⠀⠀⠀⠀⠀⣀⣾⠀⠀⠀⠀⠀⠀⠀⠈⠛⢶⣄⣰⠏⠀⠀⢀⣠⡿⢟⡿⠋
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⢻⣟⢷⡄⠀⠀⠀⠈⢷⠀⠀⠀⠀⠀⠈⠉⠓⢶⣦⠴⠶⠾⠭⣭⣍⣉⣉⠉⠉⠉⠙⠳⢶⣤⣄⣤⡴⠶⠖⠛⠋⣙⣿⠷⠿⠿⣧⣶⠟⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣽⣆⠻⣦⡀⠀⠀⠘⣇⠀⠀⠀⠀⠀⠀⠀⣼⣷⠀⠀⠀⠀⠀⠀⠈⠉⢛⣶⠶⠛⠉⠉⠁⠀⠉⠙⣳⣶⠞⠋⠉⠀⣀⡶⠾⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣎⠌⢳⣄⠀⠀⢹⣆⠀⠀⠀⠀⠀⣼⠃⣿⠀⠀⠀⠀⠀⠀⠀⣠⠟⠁⠀⠀⠀⠀⠀⣠⣴⡿⠛⠁⢀⣤⠶⠛⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⡀⠙⣧⡀⠀⢻⡄⠀⠀⠀⣸⠇⠀⣿⠀⠀⠀⠀⠀⢠⡾⠃⠀⠀⠀⢀⣤⠾⣫⡿⢋⣀⡴⠞⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣆⠈⠻⣆⠈⣷⠀⠀⣰⡏⠀⠀⢻⠀⠀⠀⢀⣴⠏⠀⠀⣀⣴⠞⠋⣠⣾⣿⠾⠛⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣄⠘⢷⡼⣇⢀⡟⠀⠀⠀⢸⠀⠀⣠⠟⠁⣠⡴⠞⠉⢀⣠⡾⠟⠋
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣦⡀⠹⣿⡾⠁⠀⠀⠀⢸⣀⣾⣣⠶⠛⠁⣀⣤⠾⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⠈⢿⡀⠀⠀⢀⣼⠟⠋⢀⣠⠴⠛⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠷⣜⣧⠀⣠⠟⣁⣴⠞⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣾⠿⠛⠉
*/

/// @title Diamond
/// @notice Implements ERC-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol)
abstract contract Diamond {
    /// @notice Fallback function that delegates calls to the appropriate facet based on function selector
    /// @dev Reads the facet address from diamond storage and performs a delegatecall; reverts if selector is not found
    fallback() external payable virtual {
        address implementation = DiamondLib.selectorToFacet(msg.sig);
        assembly {
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())

            // Delegate call to implementation
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy returned data
            returndatacopy(0, 0, returndatasize())

            // Revert or return based on the result
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
