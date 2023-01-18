// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IStrategy.sol";
import "./IVault.sol";

contract Harvester {
    function harvestVault(address[] memory retVaults) public {
        for (uint256 i = 0; i < retVaults.length; i++) {
            address strategyContract = IVault(retVaults[i]).strategy();
            IStrategy(strategyContract).managerHarvest();
        }
    }
}
