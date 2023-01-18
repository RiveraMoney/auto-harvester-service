// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for Rivera Factory Contract.:
 */
interface IRiveraFactory {
    function listAllVaults() external view returns (address[] memory);
}
