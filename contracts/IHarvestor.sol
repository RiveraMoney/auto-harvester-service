// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for Harvetor Contract.:
 */

interface IHarvestor {
    function harvestVault(address[] memory) external;
}
