pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "../contracts/Resolver.sol";
import "../contracts/Harvester.sol";
import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";
import "@pancakeswap-v3-core/interfaces/IPancakeV3Factory.sol";
import "../contracts/interfaces/IStrategy.sol";
import "../contracts/interfaces/IRiveraAutoCompoundingVaultV2.sol";
import "../contracts/interfaces/IRiveraAutoCompoundingVaultFactoryV2.sol";
//import Ichainlink
import "../contracts/interfaces/IChainlinkPriceFeed.sol";
import "../contracts/interfaces/IV3SwapRouter.sol";


///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract ResolverTest is Test {
    Resolver resolver;
    Harvester harvester;
    // IRiveraAutoCompoundingVaultV2 vault;
    // IStrategy strategy;
    IRiveraAutoCompoundingVaultFactoryV2 vaultFactory;

    address PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

   

    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;
    address _bnbx=0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275;
    address _ankrEth=0xe05A08226c49b636ACf99c40Da8DC6aF83CE5bB3;
    address _eth=0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address _whale = 0xD183F2BBF8b28d9fec8367cb06FE72B88778C86B;        //35 Mil whale 35e24
    address _whaleBnb=	0x8FA59693458289914dB0097F5F366d771B7a7C3F;
    address _whaleEth=0x34ea4138580435B5A521E460035edb19Df1938c1;
    uint256 _maxUserBal = 15e24;
    address _user1=0x150CC4F90516C23e64231D2B92d737893DBb2515;
    address _user2=0x29782e6eefef1255D1DDC2Bd1b4851B890614868;
    address _user3=0x2aCC49a84919Ab9Cf0eb6576432E9b09D78650E6;  
    address _user4=0xcf288Dc70983D17C83EA1b80579b211c51043801;



    //cakepool params
    // bool _isTokenZeroDeposit = true;
    int24 _tickLower = -59310;
    int24 _tickUpper = -57100;
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
    // address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // //libraries
    address _tickMathLib = 0x21071Cd83f468856dC269053e84284c5485917E1;
    address _sqrtPriceMathLib = 0xA9C3e24d94ef6003fB6064D3a7cdd40F87bA44de;
    address _liquidityMathLib = 0xA7B88e482d3C9d17A1b83bc3FbeB4DF72cB20478;
    address _safeCastLib = 0x3dbfDf42AEbb9aDfFDe4D8592D61b1de7bd7c26a;
    address _liquidityAmountsLib = 0x672058B73396C78556fdddEc090202f066B98D71;
    address _fullMathLib = 0x46ECf770a99d5d81056243deA22ecaB7271a43C7;
    address  _rewardtoNativeFeed=0xcB23da9EA243f53194CBc2380A6d4d9bC046161f;
    // address  _assettoNativeFeed=0xD5c40f5144848Bd4EF08a9605d860e727b991513;


    //usdt bnb pool
    address[] _rewardToLp0AddressPath = [_cake, _usdt];
    uint24[] _rewardToLp0FeePath = [2500];
    address[] _rewardToLp1AddressPath = [_cake, _wbnb];
    uint24[] _rewardToLp1FeePath = [2500];
    address _stake = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;
    address _assettoNativeFeedUsdtBnbPool=0xD5c40f5144848Bd4EF08a9605d860e727b991513;
    

    //BNBx / WBNB pool params
    address[] _rewardToLp0AddressPathBnbPool = [_cake,_wbnb, _bnbx];
    uint24[] _rewardToLp0FeePathBnbPool = [2500,500];
    address[] _rewardToLp1AddressPathBnbPool = [_cake, _wbnb];
    uint24[] _rewardToLp1FeePathBnbPool = [2500];
    address _stakeBnbPool=0x77B27c351B13Dc6a8A16Cc1d2E9D5e7F9873702E;//BNBx / WBNB
    address  _assettoNativeFeedBnbPool=address(0);
    uint256 depositAmount1=100e18;///vault 1 deposit amount


    //ETH / ankrETH pool params
    address[] _rewardToLp0AddressPathEthPool = [_cake,_wbnb, _eth];
    uint24[] _rewardToLp0FeePathEthPool = [2500,2500];
    address[] _rewardToLp1AddressPathEthPool = [_cake,_wbnb,_eth, _ankrEth];
    uint24[] _rewardToLp1FeePathEthPool = [2500,2500,500];
    address _stakeEthPool=0x61837a8a78F42dC6cfEd457c4eC1114F5e2d90f4;//BNBx / WBNB
    address  _assettoNativeFeedEthPool=0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726;
    uint256 depositAmount2=10e18;  ////vault 2 deposit amount


    //common address
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;
    VaultType _vaultType;

    function setUp() public {
        ///@dev all deployments will be made by the user
        vm.startPrank(_user1);
        vaultFactory = IRiveraAutoCompoundingVaultFactoryV2(
            0x6AB8c9590bD89cBF9DCC90d5efEC4F45D5d219be
        );
        resolver= new Resolver(
            address(vaultFactory),
            PANCAKE_FACTORY,
            _cake,
            _wbnb,
            700000
        );
        vm.stopPrank();
    }

    function test_Checker() public {
        address[] memory retVaults;
        bool canExec;
        bytes memory execPayload;
        vm.startPrank(_user1);
        (canExec, execPayload) = resolver.checker();
        (, retVaults) = this.decodePayload(execPayload);
        console.log("canExec", canExec);
        //log all vaults
        for (uint256 i = 0; i < retVaults.length; i++) {
            console.log("vault", retVaults[i]);
        }
        vm.stopPrank();
    }

    function test_GetHarvestAmount(uint256 time,uint256 swapAmount) public {

        // vm.roll(block.timestamp + 1 days);
        // vm.roll(block.number+100);
        vm.warp(block.timestamp + 7*24*60*60);
        // vm.assume(time>7 days && time< 500 days);
        // vm.warp(block.timestamp + time);
        vm.assume(swapAmount < 100e18 && swapAmount > 10e18);
        _performSwapInBothDirections(swapAmount);
        vm.startPrank(_user1);
        address[] memory allVaults = vaultFactory.listAllVaults();
        address vault = allVaults[0];
        IRiveraAutoCompoundingVaultV2 vaultContract = IRiveraAutoCompoundingVaultV2(vault);
        IStrategy strategy = IStrategy(vaultContract.strategy());
        bool isVaultAssetNative= vaultContract.asset() == _wbnb;
        uint256 lpRewardsAvailable = strategy.lpRewardsAvailable();
        uint256 lpRewardsAvailableVault=isVaultAssetNative?lpRewardsAvailable:lpRewardsAvailable * tokenToNativeTokenConversionRate(_assettoNativeFeedBnbPool) / 1e18;
        uint256 rewardsAvailable = strategy.rewardsAvailable();
        uint256 rewardsAvailableVault=rewardsAvailable * tokenToNativeTokenConversionRate(_rewardtoNativeFeed) / 1e18;
        uint256 harvestAmountVault=lpRewardsAvailableVault+rewardsAvailableVault;
        uint256 harvestAmountResolver=resolver.getHarvestAmount(vault);
        assertEq(harvestAmountVault, harvestAmountResolver);
        vm.stopPrank();
    } 

    function test_NetCapitalDeposited(uint256 depositAmount) public {
        address[] memory allVaults = vaultFactory.listAllVaults();
        address vault ;
        //approve vault[0] to spend 100e18
        //check for allvaults
        vm.assume(depositAmount < 20e18 && depositAmount > 10e18);
        for (uint256 i = 0; i < allVaults.length; i++) {
            vault = allVaults[i];
            IRiveraAutoCompoundingVaultV2 vaultContract = IRiveraAutoCompoundingVaultV2(vault);
            IStrategy strategy = IStrategy(vaultContract.strategy());
            bool isVaultAssetNative= vaultContract.asset() == _wbnb;
            vm.startPrank(isVaultAssetNative?_whaleBnb:_whaleEth);
            IERC20(vaultContract.asset()).transfer(_user3, depositAmount);
            vm.stopPrank();
            vm.startPrank(_user3);
            IERC20(vaultContract.asset()).approve(vault, depositAmount);
            vaultContract.deposit(depositAmount, _user3);
            //get assettoNative feed from strategy
            address _assettoNativeFeed=strategy.assettoNativeFeed();
            uint256 netCapitalDepositedVault=isVaultAssetNative?vaultContract.totalAssets(): vaultContract.totalAssets() * tokenToNativeTokenConversionRate(_assettoNativeFeed) / 1e18;
            uint256 netCapitalDepositedResolver = resolver.netCapitalDeposited(address(vaultContract));
            assertEq(netCapitalDepositedResolver, netCapitalDepositedVault);
            vm.stopPrank();
        }
    }

    function test_GetStepWiseH(uint256 vaultAmount)  public {
        vm.assume(vaultAmount < vaultTvlCap && vaultAmount > 1e18);
        uint256 cost = resolver.costOfHarvest();
        // uint256 x1 = (1 + Math.sqrt(1 + 8 * vaultAmount / cost)) / (2 * vaultAmount / cost);
        // uint256 stepWiseH= x1 * vaultAmount;
        uint256 H = resolver.getStepwiseH(cost, vaultAmount);
        assertEq(H>0,true);
    }

    function tokenToNativeTokenConversionRate(address feed) public view returns (uint256) {
        IChainlinkPriceFeed priceFeed = IChainlinkPriceFeed(feed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    } 

    function _performSwapInBothDirections(uint256 swapAmount) internal {
        vm.startPrank(_whaleBnb);
        IERC20(_wbnb).transfer(_user2, swapAmount*2);
        vm.stopPrank();
        vm.startPrank(_user2);
        IERC20(_wbnb).approve(_router, type(uint256).max);
        uint256 _bnbxReceived = IV3SwapRouter(_router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                _wbnb,
                _bnbx,
                500,
                _user2,
                swapAmount,
                0,
                0
            )
        );
        IV3SwapRouter(_router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                _wbnb,
                _usdt,
                500,
                _user2,
                _bnbxReceived,
                0,
                0
            )
        );
        vm.stopPrank();
    }

    function decodePayload(bytes calldata payload) public pure returns (bytes4 selector, address[] memory arguments) {
        (selector) = abi.decode(payload, (bytes4));
        (arguments) = abi.decode(payload[4:], (address[]));
    }
}