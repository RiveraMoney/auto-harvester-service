// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IRiveraFactory.sol";
import "./interfaces/IHarvestor.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IlpContract.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IChainlinkPriceFeed.sol";


contract Resolver is Ownable {     //Emit events in relevant places

    // Type Declarations
    uint32 public averageGasOfHarvestingSingleVault;
    address public riveraFactory;
    address public PANCAKE_FACTORY;
    address public REWARD;
    address public NATIVE_GAS;

    event VaultHarvestGasChange(uint32 averageGasOfHarvestingSingleVaultOld, uint32 averageGasOfHarvestingSingleVaultNew);


    //Constructor will stay the same
    constructor(
        address _riveraFactory,
        address _PANCAKE_FACTORY,       //0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865  V3 Factory
        address _REWARD,
        address _NATIVE_GAS,     //Native gas should be set in wrapped as that will be used in the LP pools
        uint32 _averageGasOfHarvestingSingleVault
    ) {
        riveraFactory = _riveraFactory;
        PANCAKE_FACTORY = _PANCAKE_FACTORY;
        REWARD = _REWARD;
        NATIVE_GAS = _NATIVE_GAS;
        averageGasOfHarvestingSingleVault = _averageGasOfHarvestingSingleVault;
    }

    function tokenToNativeTokenConversionRate(address feed) public view returns (uint256) {
        IChainlinkPriceFeed priceFeed = IChainlinkPriceFeed(feed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // fuction using new algo
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 j = 0;
        address[] memory allVaults = _getAllVaults();
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

    //return all the vaults created
    function _getAllVaults() internal view returns (address[] memory) {
        address[] memory vaults = IRiveraFactory(riveraFactory).listAllVaults();
        return vaults;
    }

    function netCapitalDeposited(address _vault) public view returns (uint256 _amount) {
        uint256 netInvestedCapital = IVault(_vault).totalAssets();
        address vaultAsset = IVault(_vault).asset();
        if(vaultAsset == NATIVE_GAS){
            return netInvestedCapital;
        }else{
            address strategyContract = IVault(_vault).strategy();
            address assettoNativeFeed = IStrategy(strategyContract).assettoNativeFeed();
            uint256 vaultAssetValue = tokenToNativeTokenConversionRate(assettoNativeFeed);
            uint256 decimals = _getFeedDecimals(assettoNativeFeed);
            uint256 netInvestedCapitalNative = (vaultAssetValue * netInvestedCapital)/(10**decimals);
            return netInvestedCapitalNative;
        }
    }

    //Cost of harvest does not represent the cost incurred by us here. Gelato has it's own additional cost as well. We should get the cost from gelato.
    //The challenge here is gelato charges at a call level. We harvest all vaults that satisfies the harvest condition in one call. So the cost we would receive from gelato is for harvesting multiple vaults.
    //To figure out the cost of harvesting one vault we would need the number of vaults to be harvested. The number of vaults to be harvested would in turn depend on the cost of harvesting one vault.

    //An alternate approach I have in mind is. We deploy a checker contract for each vault deployed in Rivera. The checker would easily get the cost of harvesting it's own vault alone. 
    //After getting the cost we would compute the harvestability condition and call harvest.
    //1) Which account should have the GEL tokens in order for the call to execult successfully?
    //2) If each of the checker contracts need the GEL tokens to pay then this architecture won't work.
    function costOfHarvest() public view returns (uint256 _amount) {        //Need to update this gasEstimation and gasPrice will change for DEx v3. Have to also account for any cost from gelato side.
        uint256 costHarvest = averageGasOfHarvestingSingleVault * tx.gasprice;
        return costHarvest;
    }


    function getHarvestAmount(address _vault) public view returns (uint256) {
        uint256 lpRewardsAvailableNative;
        address strategyContract = IVault(_vault).strategy();
        uint256 lpRewardsAvailable = IStrategy(strategyContract).lpRewardsAvailable();
        address vaultAsset = IVault(_vault).asset();
        if(vaultAsset == NATIVE_GAS) {
            lpRewardsAvailableNative = lpRewardsAvailable;
        } else {
            address assettoNativeFeed = IStrategy(strategyContract).assettoNativeFeed();
            uint256 vaultAssetValue = tokenToNativeTokenConversionRate(assettoNativeFeed);
            lpRewardsAvailableNative = (vaultAssetValue * lpRewardsAvailable)/(10**_getFeedDecimals(assettoNativeFeed));
        }
        uint256 rewardsAvailable = IStrategy(strategyContract).rewardsAvailable();
        address rewardtoNativeFeed = IStrategy(strategyContract).rewardtoNativeFeed();
        uint256 rewardAssetValue = tokenToNativeTokenConversionRate(rewardtoNativeFeed);
        uint256 rewardsAvailableNative = (rewardsAvailable * rewardAssetValue)/(10**_getFeedDecimals(rewardtoNativeFeed));
        return lpRewardsAvailableNative + rewardsAvailableNative;
    }
 
    function getStepwiseH(uint256 cost, uint256 vaultAmount) public pure returns (uint256 H) {
        uint256 x = (1 + Math.sqrt(1 + 8 * vaultAmount / cost)) / (2 * vaultAmount / cost);
        H = x * vaultAmount;
    }

    function setAverageGasOfHarvestingSingleVault(uint32 averageGasOfHarvestingSingleVault_) external onlyOwner {
        emit VaultHarvestGasChange(averageGasOfHarvestingSingleVault, averageGasOfHarvestingSingleVault_);
        averageGasOfHarvestingSingleVault = averageGasOfHarvestingSingleVault_;
    }

    function _getFeedDecimals(address feed) public view returns (uint8) {
        IChainlinkPriceFeed priceFeed = IChainlinkPriceFeed(feed);
        return priceFeed.decimals();
    }
}
