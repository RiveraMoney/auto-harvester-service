// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for Vault Contract.:
 */
interface IVault {
    function strategy() external view returns (address);
    function balance() external view returns (uint) ;
}
