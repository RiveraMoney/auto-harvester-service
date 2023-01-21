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
        require(
            msg.sender == i_owner || msg.sender == whitelistedAddress,
            "!not whitelisted"
        );
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
            if (retVaults[i] == address(0)) {
                continue;
            } else {
                address strategyContract = IVault(retVaults[i]).strategy();
                IStrategy(strategyContract).harvest();
            }
        }
    }
}
