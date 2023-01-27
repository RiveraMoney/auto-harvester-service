// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IRiveraFactory.sol";
import "./IHarvestor.sol";
import "./IVault.sol";
import "./IStrategy.sol";
import "./IPancakeFactory.sol";
import "./IlpContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Resolver {
    using SafeMath for uint256;

    // Type Declarations
    address public riveraFactory;
    address public PANCAKE_FACTORY;
    address public REWARD;
    address public NATIVE_GAS;
    address public BASE_CURRENCY;

    constructor(
        address _riveraFactory,
        address _PANCAKE_FACTORY,
        address _REWARD,
        address _NATIVE_GAS,
        address _BASE_CURRENCY
    ) {
        riveraFactory = _riveraFactory;
        PANCAKE_FACTORY = _PANCAKE_FACTORY;
        REWARD = _REWARD;
        NATIVE_GAS = _NATIVE_GAS;
        BASE_CURRENCY = _BASE_CURRENCY;
    }

    function arrangeTokens(address tokenA, address tokenB)
        public
        pure
        returns (address, address)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function tokenToBaseTokenConversionRate(address token)
        public
        view
        returns (uint256)
    {
        if (token == BASE_CURRENCY) {
            return 1;
        }
        address lpAddress = IPancakeFactory(PANCAKE_FACTORY).getPair(
            token,
            BASE_CURRENCY
        );
        (uint112 _reserve0, uint112 _reserve1, ) = IlpContract(lpAddress)
            .getReserves();
        (address token0, address token1) = arrangeTokens(token, BASE_CURRENCY);
        return token0 == token ? _reserve1 / _reserve0 : _reserve0 / _reserve1;
    }

    function lpTokenToBaseTokenConversionRate(address lpToken)
        public
        view
        returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = IlpContract(lpToken)
            .getReserves();
        address token0 = IlpContract(lpToken).token0();
        address token1 = IlpContract(lpToken).token1();
        uint256 reserve0InBaseToken = (tokenToBaseTokenConversionRate(token0)) *
            _reserve0;
        uint256 reserve1InBaseToken = (tokenToBaseTokenConversionRate(token1)) *
            _reserve1;

        uint256 lpTotalSuppy = IlpContract(lpToken).totalSupply();

        return (reserve0InBaseToken + reserve1InBaseToken) / lpTotalSuppy;
    }

    // fuction using new algo
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 j = 0;
        address[] memory allVaults = getAllVaults();
        address[] memory retVaults = new address[](allVaults.length);
        canExec = false;

        for (uint256 i = 0; i < allVaults.length; i++) {
            address vault = allVaults[i];
            uint256 harvestAmount = getHarvestAmount(vault);
            uint256 cost = costOfHarvest();
            uint256 vaultAmount = netCapitalDeposited(vault);
            if (cost > vaultAmount) {
                continue;
            }
            uint256 H = getStepwiseH(cost, vaultAmount);
            if (harvestAmount >= H) {
                canExec = true;
                retVaults[j++] = vault;
            }
        }

        execPayload = abi.encodeWithSelector(
            IHarvestor.harvestVault.selector,
            (retVaults)
        );
    }

    // temperory checker
    /*function checker()
        external
        view
        returns (
            bool canExec,
            bytes memory execPayload,
            address[] memory
        )
    {
        // address[] memory retVaults;
        uint256 j = 0;
        address[] memory allVaults = getAllVaults();
        address[] memory retVaults = new address[](allVaults.length);
        canExec = false;
        for (uint256 i = 0; i < allVaults.length; i++) {
            address vault = allVaults[i];
            uint256 harvestAmount = getHarvestAmount(vault);
            // uint256 x = (1 + sqrt(1 + (8 * vaultAmount) / cost)) /
            //     ((2 * vaultAmount) / cost);
            // uint256 H = x * vaultAmount;
            // uint256 H = getStepwiseH(vault);
            if (harvestAmount > 10000000000000000) {
                canExec = true;
                retVaults[j++] = vault;
            }
        }

        execPayload = abi.encodeWithSelector(
            IHarvestor.harvestVault.selector,
            (retVaults)
        );
        return (canExec, execPayload, retVaults);
    }*/

    //return all the vaults created
    function getAllVaults() public view returns (address[] memory) {
        address[] memory vaults = IRiveraFactory(riveraFactory).listAllVaults();
        return vaults;
    }

    function netCapitalDeposited(address _vault)
        public
        view
        returns (uint256 _amount)
    {
        uint256 netInvestedCapital = IVault(_vault).balance();
        address strategyContract = IVault(_vault).strategy();
        address lpPool = IStrategy(strategyContract).stake();
        uint256 lpTokenValue = lpTokenToBaseTokenConversionRate(lpPool);
        uint256 netInvestedCapitalBase = lpTokenValue * netInvestedCapital;
        return netInvestedCapitalBase;
    }

    function costOfHarvest() public view returns (uint256 _amount) {
        uint256 gasEstimation = 533966;
        uint256 gasPrice = 7303301330; //6;  //temmp //get price from some oracle;

        uint256 costHarvest = gasEstimation * gasPrice;
        uint256 nativeGasToBaseConversionRate = tokenToBaseTokenConversionRate(
            NATIVE_GAS
        );
        uint256 costOfHarvestBase = nativeGasToBaseConversionRate * costHarvest;
        return costOfHarvestBase;
    }

    function getHarvestAmount(address _vault) public view returns (uint256) {
        address strategyContract = IVault(_vault).strategy();
        uint256 currRewardsAvailable = IStrategy(strategyContract)
            .rewardsAvailable();
        uint256 rewardToBaseConversionRate = tokenToBaseTokenConversionRate(
            REWARD
        );
        uint256 currRewardsAvailableBase = currRewardsAvailable *
            rewardToBaseConversionRate;
        ///do the conversion
        return currRewardsAvailableBase;
    }

    function getStepwiseH(uint256 cost, uint256 vaultAmount)
        public
        pure
        returns (uint256 H)
    {
        // uint256 vaultAmount = netCapitalDeposited(vault);
        // uint256 cost = costOfHarvest();
        uint256 x = uint256(1).add(
            (sqrt((uint256(1).add((uint256(8).mul(vaultAmount)))).div(cost)))
        );
        uint256 y = (uint256(2).mul(vaultAmount)).div(cost);

        H = x.mul(vaultAmount).div(y);
    }

    function getStepwiseHTemp(address vault) public view returns (uint256 H) {
        uint256 vaultAmount = netCapitalDeposited(vault);
        uint256 cost = costOfHarvest();
        uint256 x = uint256(1).add(
            (sqrt((uint256(1).add((uint256(8).mul(vaultAmount)))).div(cost)))
        );
        uint256 y = (uint256(2).mul(vaultAmount)).div(cost);

        H = x.mul(vaultAmount).div(y);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
