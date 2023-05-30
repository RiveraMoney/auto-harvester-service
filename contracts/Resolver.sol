// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IRiveraFactory.sol";
import "./IHarvestor.sol";
import "./IVault.sol";
import "./IStrategy.sol";
import "./IPancakeFactory.sol";
import "./IlpContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IChainlinkPriceFeed.sol";


contract Resolver {     //Emit events in relevant places
    using SafeMath for uint256;

    // Type Declarations
    address public riveraFactory;
    address public PANCAKE_FACTORY;
    address public REWARD;
    address public NATIVE_GAS;


    //Constructor will stay the same
    constructor(
        address _riveraFactory,
        address _PANCAKE_FACTORY,//0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865  V3 Factory
        address _REWARD,
        address _NATIVE_GAS
    ) {
        riveraFactory = _riveraFactory;
        PANCAKE_FACTORY = _PANCAKE_FACTORY;
        REWARD = _REWARD;
        NATIVE_GAS = _NATIVE_GAS;
    }

    function arrangeTokens(address tokenA, address tokenB)
        public
        pure
        returns (address, address)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }


    function tokenToNativeTokenConversionRate(address feed)      //Should change this function to use DEx V3. Follow what is done in convertAmount0ToAmount1 and convertAmount1ToAmount0 in CakeLpStakingV2.sol
        public
        view
        returns (uint256)
    {
        //get chainlink price feed
        IChainlinkPriceFeed priceFeed = IChainlinkPriceFeed(feed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // function tokenToBaseTokenConversion(address token,uint256 tokenAmount)      //Should change this function to use DEx V3. Follow what is done in convertAmount0ToAmount1 and convertAmount1ToAmount0 in CakeLpStakingV2.sol
    //     public
    //     view
    //     returns (uint256 baseAmount)
    // {
    //     if (token == BASE_CURRENCY) {
    //         return 1;
    //     }
    //     address stake = IPancakeFactory(PANCAKE_FACTORY).getPool(
    //         token,
    //         BASE_CURRENCY,
    //         500
    //     );
    //     (uint160 sqrtPriceX96, , , , , , ) = IlpContract(stake)
    //         .slot0();
    //     baseAmount = IFullMathLib(fullMathLib).mulDiv(
    //         IFullMathLib(fullMathLib).mulDiv(
    //             tokenAmount,
    //             FixedPoint96.Q96,
    //             sqrtPriceX96
    //         ),
    //         FixedPoint96.Q96,
    //         sqrtPriceX96
    //     );
    // }

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
    {       //This function gives the total value of the vault. We can just call totalAssets() function of the vault contract to get the total value of the vault in denomination asset
        
        uint256 netInvestedCapital = IVault(_vault).totalAssets();
        //get vault asset
        address vaultAsset = IVault(_vault).asset();
        if(vaultAsset == NATIVE_GAS){
            return netInvestedCapital;
        }else{
            //get asset feed address from strategy
            address strategyContract = IVault(_vault).strategy();
            address assettoNativeFeed = IStrategy(strategyContract).assettoNativeFeed();
            uint256 vaultAssetValue = tokenToNativeTokenConversionRate(assettoNativeFeed);
            //getdecimals
            uint256 decimals= _getFeedDecimals(assettoNativeFeed);
            uint256 netInvestedCapitalBase = (vaultAssetValue * netInvestedCapital)/(10**decimals);
            return netInvestedCapitalBase;
        }
    }

    function netCapitalDepositedTemp()
        public
        view
        returns (uint256 _amount)
    {       //This function gives the total value of the vault. We can just call totalAssets() function of the vault contract to get the total value of the vault in denomination asset
        
            uint256 netInvestedCapital = 20e18;
            address assettoNativeFeed = 0xD5c40f5144848Bd4EF08a9605d860e727b991513;
            uint256 vaultAssetValue = tokenToNativeTokenConversionRate(assettoNativeFeed);
            //getdecimals
            uint256 decimals= _getFeedDecimals(assettoNativeFeed);
            uint256 netInvestedCapitalBase = (vaultAssetValue * netInvestedCapital)/(10**decimals);
            return netInvestedCapitalBase;
    }

    //Cost of harvest does not represent the cost incurred by us here. Gelato has it's own additional cost as well. We should get the cost from gelato.
    //The challenge here is gelato charges at a call level. We harvest all vaults that satisfies the harvest condition in one call. So the cost we would receive from gelato is for harvesting multiple vaults.
    //To figure out the cost of harvesting one vault we would need the number of vaults to be harvested. The number of vaults to be harvested would in turn depend on the cost of harvesting one vault.

    //An alternate approach I have in mind is. We deploy a checker contract for each vault deployed in Rivera. The checker would easily get the cost of harvesting it's own vault alone. 
    //After getting the cost we would compute the harvestability condition and call harvest.
    //1) Which account should have the GEL tokens in order for the call to execult successfully?
    //2) If each of the checker contracts need the GEL tokens to pay then this architecture won't work.
    function costOfHarvest() public view returns (uint256 _amount) {        //Need to update this gasEstimation and gasPrice will change for DEx v3. Have to also account for any cost from gelato side.
        uint256 gasEstimation = 533966;  ///  todo: get this from gelato
        // uint256 gasPrice = 7303301330; //6; tx.gasprice()
        uint256 gasPrice = tx.gasprice ; //6; 

        uint256 costHarvest = gasEstimation * gasPrice;
        
        return costHarvest;
    }


    function getHarvestAmount(address _vault) public view returns (uint256) {       //Should also use the unharvested LP fees here with cake staking rewards. lpRewardsAvailable() function in the CakeLpStakingV2.sol returns this in the denomination asset of the vault.
      
        //call rewardsAvailable() function of the strategy contract and lpRewardsAvailable() function of the cake staking contract
        uint256 lpRewardsAvailableNative;
        address strategyContract = IVault(_vault).strategy();
        uint256 lpRewardsAvailable = IStrategy(strategyContract)
            .lpRewardsAvailable();
        address vaultAsset = IVault(_vault).asset();
        if(vaultAsset == NATIVE_GAS){
            lpRewardsAvailableNative= lpRewardsAvailable;
        }else{
            //get asset feed address from strategy
            address assettoNativeFeed = IStrategy(strategyContract).assettoNativeFeed();
            //get  decimals
            uint256 decimals= _getFeedDecimals(assettoNativeFeed);
            uint256 vaultAssetValue = tokenToNativeTokenConversionRate(assettoNativeFeed);
            lpRewardsAvailableNative = (vaultAssetValue * lpRewardsAvailable)/(10**decimals);
        }
        
        uint256 rewardsAvailable = IStrategy(strategyContract)
            .rewardsAvailable();
        //get reward asset feed address from strategy
        address rewardtoNativeFeed = IStrategy(strategyContract).rewardtoNativeFeed();
        uint256 rewardAssetValue = tokenToNativeTokenConversionRate(
            rewardtoNativeFeed
        );
        //get  decimals
        uint256 decimals= _getFeedDecimals(rewardtoNativeFeed);
        uint256 rewardsAvailableBase= (rewardsAvailable * rewardAssetValue)/(10**decimals);
        return lpRewardsAvailableNative + rewardsAvailableBase;
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

    //Need some explanation on this function
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

    function _getFeedDecimals(address feed) public view returns (uint8) {
        IChainlinkPriceFeed priceFeed = IChainlinkPriceFeed(feed);
        return priceFeed.decimals();
    }
}
