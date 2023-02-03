// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IStrategy.sol";
import "./IVault.sol";

error Not_whitelisted();

contract Harvester {        //Emit event on harvest to do analysis. Make the cost used to calculate harvestability of each vault and total cost paid to Gelato as part of the event.
    address public whitelistedAddress;
    address private immutable i_owner;
    //Have a harvest run id here that keeps incrementing on every run

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
