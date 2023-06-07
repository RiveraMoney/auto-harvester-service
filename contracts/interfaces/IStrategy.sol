// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    function vault() external view returns (address);

    function chef() external view returns (address);

    function stake() external view returns (address);

    function reward() external view returns (address);

    function lpToken0() external view returns (address);

    function lpToken1() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function managerHarvest() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function router() external view returns (address);

    function poolId() external view returns (uint256);

    function rewardToLp0Route(uint256) external view returns (address);

    function rewardToLp1Route(uint256) external view returns (address);

    function lpRewardsAvailable() external view returns (uint256);
    function rewardsAvailable() external view returns (uint256);
    function owner() external view returns (address);

    function rewardtoNativeFeed() external view returns (address);
    function assettoNativeFeed() external view returns (address);

}
