// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IStrategy.sol";
import "./interfaces/IRiveraAutoCompoundingVaultV2.sol";
import "./lib/WhitelistFilter.sol";

contract Harvester is WhitelistFilter {
    uint256 harvestRunId = 1;

    event HarvestRun(uint256 harvestRunId, uint256 numVaultsHarvested, address[] retVaults);

    function harvestVault(address[] memory retVaults) public onlyWhitelisted {
        for (uint256 i = 0; i < retVaults.length; i++) {
            if (retVaults[i] == address(0)) {
                break;
            } else {
                address strategyContract = IRiveraAutoCompoundingVaultV2(retVaults[i]).strategy();
                IStrategy(strategyContract).harvest();
            }
        }
        emit HarvestRun(harvestRunId++, retVaults.length, retVaults);
    }
}
