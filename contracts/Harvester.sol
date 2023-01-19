// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IStrategy.sol";
import "./IVault.sol";

error Not_whitelisted();

contract Harvester {
    address public whitelistedAddress;
    address private immutable i_owner;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner || msg.sender != whitelistedAddress)
            revert Not_whitelisted();
        _;
    }

    constructor() {
        i_owner = msg.sender;
        whitelistedAddress = msg.sender;
    }

    function updateWhitelist(address _whitelistedAddress) public onlyOwner {
        whitelistedAddress = _whitelistedAddress;
    }

    function harvestVault(address[] memory retVaults) public onlyOwner {
        for (uint256 i = 0; i < retVaults.length; i++) {
            address strategyContract = IVault(retVaults[i]).strategy();
            IStrategy(strategyContract).managerHarvest();
        }
    }
}
