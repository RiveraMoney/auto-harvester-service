const { expect, assert } = require("chai")
const { ethers, network } = require("hardhat")
// require("@nomiclabs/hardhat-ethers")
const { GelatoOpsSDK, isGelatoOpsSupported } = require("@gelatonetwork/ops-sdk")

const {
    pancakeFactoryAbi,
    riveraFactoryVaultAbi,
    pancakePairAbi,
    strategyAbi,
    vaultAbi,
    resolverAbi,
    harvesterAbi,
    treasuryAbi,
} = require("../../utils/Abis")

//constants
const riveraFactory = "0xa1F54f9115c12Bd25f0dD81CC661Af8bD830D519"
const PANCAKE_FACTORY = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
const REWARD = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const NATIVE_GAS = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
const BASE_CURRENCY = "0x55d398326f99059fF775485246999027B3197955"
const PRIVATE_KEY = process.env.PRIVATE_KEY

describe("GelatoExample", () => {
    let accounts, GelatoResolver, Harvester, VaultFactory, Vaults

    // let provider = new ethers.providers.JsonRpcProvider(network.config.url)

    before(async () => {
        accounts = await ethers.getSigners(1)
        const chainId = network.config.chainId
        console.log("chainid", chainId)
        const gelatoOps = new GelatoOpsSDK(chainId, accounts[0])
        // console.log("accounts", accounts[0])

        let accountToImpersonate = "0x4977B94DCA14A126025755815DB1162ff4f66242"
        await network.provider.send("hardhat_impersonateAccount", [
            accountToImpersonate,
        ])
        //for tojen transfer
        const whale = ethers.provider.getSigner(accountToImpersonate)
        // console.log(whale, "whale")
        // const resp = await whale.sendTransaction({
        //     to: "0x4c820EAd2af56eF7e577eB533eF326A452214119",
        //     value: ethers.utils.parseEther("0.002"),
        // })
        // console.log("funded from miner account, @ blocknum:", resp.blockNumber)

        //end token tranfes

        //gelatopreSEtup
        // await gelaotoPreSetup(accounts[0])
        //end gelatopresetup

        // const gelatoOps = new GelatoOpsSDK(chainId, whale)

        // console.log(gelatoOps, "gelatoops")
        if (isGelatoOpsSupported(chainId)) {
            console.log("gelato supported")
        }

        //Deplloy Gelato
        const gelatores = await ethers.getContractFactory("Resolver")
        GelatoResolver = await gelatores.deploy(
            riveraFactory,
            PANCAKE_FACTORY,
            REWARD,
            NATIVE_GAS,
            BASE_CURRENCY
        )
        await GelatoResolver.deployed()
        // console.log("Gelato Resolver deployed to:", GelatoResolver.address)

        //Deplloy Gelato Harvestpr
        const _harvester = await ethers.getContractFactory("Harvester")
        Harvester = await _harvester.deploy()
        await Harvester.deployed()
        // console.log("Harvester deployed to:", Harvester)

        // Rivera Factory Vault
        VaultFactory = await ethers.getContractAt(
            riveraFactoryVaultAbi,
            "0xa1F54f9115c12Bd25f0dD81CC661Af8bD830D519",
            accounts[0]
            // whale
        )
        console.log("VaultFactory", VaultFactory.address)
        Vaults = await VaultFactory.listAllVaults()
        console.log("Vaults", Vaults)

        const gasFeeData = await ethers.provider.getFeeData()
        if (!gasFeeData.gasPrice)
            throw new Error("ethers.js did not return prevailing gas price!")
        console.log(
            `Prevailing gas price in the blockchain for transaction: ${gasFeeData.gasPrice.toNumber()}`
        )

        // Gelato SDK

        // const { taskId, tx } = await gelatoOps.createTask({
        //     execAddress: Harvester.address,
        //     execSelector: Harvester.interface.getSighash(
        //         "harvestVault(address[])"
        //     ),
        //     // execAbi: JSON.stringify(harvesterAbi),
        //     resolverAddress: GelatoResolver.address,
        //     resolverData: GelatoResolver.interface.getSighash("checker()"),
        //     // resolverAbi: JSON.stringify(resolverAbi),
        //     name: "Gelato pancake harvester",
        //     dedicatedMsgSender: true,
        //     // useTreasury: false,
        // })

        // console.log("TaskId:", taskId)
        // console.log("Transac:", tx)

        // console.log(
        //     "get dedicated msg sender",
        //     await gelatoOps.getDedicatedMsgSender()
        // )
    })

    it("tokenToBaseTokenConversionRate check for reward", async () => {
        let k1 = await tokenToBaseTokenConversionRate(REWARD, accounts[0])
        console.log("k1", k1)
        let k2 = await GelatoResolver.tokenToBaseTokenConversionRate(REWARD)
        console.log("k2", k2.toString())
        assert.equal(k1.toString(), k2.toString())
        // done()
        return new Promise((resolve) => {
            resolve()
        })
    })

    it("tokenToBaseTokenConversionRate check for native gas", async () => {
        let k1 = await tokenToBaseTokenConversionRate(NATIVE_GAS, accounts[0])
        console.log("k1", k1)
        let k2 = await GelatoResolver.tokenToBaseTokenConversionRate(NATIVE_GAS)
        console.log("k2", k2.toString())
        assert.equal(k1.toString(), k2.toString())
        return new Promise((resolve) => {
            resolve()
        })
    })

    it("lpTokenToBaseTokenConversionRate", async () => {
        let k1 = await lpTokenToBaseTokenConversionRate(
            "0x0eD7e52944161450477ee417DE9Cd3a859b14fD0",
            accounts[0]
        )
        console.log("k1", k1.toString())
        let k2 = await GelatoResolver.lpTokenToBaseTokenConversionRate(
            "0x0eD7e52944161450477ee417DE9Cd3a859b14fD0" //cake-bnb lp
        )
        console.log("k2", k2.toString())

        assert.equal(k1.toString(), k2.toString())

        return new Promise((resolve) => {
            resolve()
        })
    })

    it("netCapitalDeposited", async () => {
        let k1 = await netCapitalDeposited(Vaults[1], accounts[1])
        // console.log("netCapitalDeposited", k1.toString())
        let k2 = await GelatoResolver.netCapitalDeposited(Vaults[1])
        console.log("netCapitalDeposited", k2.toString())

        assert.equal(k1.toString(), k2.toString())

        return new Promise(async (resolve) => {
            resolve()
        })
    })

    it("getHarvestAmount", async () => {
        let k1 = await getHarvestAmount(Vaults[1], accounts[1])
        // console.log("unharvested amount", k1.toString())
        let k2 = await GelatoResolver.getHarvestAmount(Vaults[1])
        console.log("unharvested amount", k2.toString())

        assert.equal(k1.toString(), k2.toString())

        return new Promise(async (resolve) => {
            resolve()
        })
    })

    it("costOfHarvest", async () => {
        let k1 = await costOfHarvest()
        console.log("k1", k1.toString())
        let k2 = await GelatoResolver.costOfHarvest()
        // console.log(k2, k2.toString())

        // assert.equal(k1.toString(), k2.toString())

        return new Promise(async (resolve) => {
            resolve()
        })
    })

    it("getStepwiseH", async () => {
        let k1 = await getStepwiseH(Vaults[1], accounts[0])
        console.log("StepwiseH", k1.toString())
        let k2 = await GelatoResolver.getStepwiseH(
            (await costOfHarvest()).toString(),
            (await netCapitalDeposited(Vaults[1])).toString()
        )
        // let k2 = await GelatoResolver.getStepwiseHTemp(Vaults[1])
        console.log("StepwiseH", k2.toString())

        // assert.equal(k1.toString(), k2.toString())

        return new Promise(async (resolve) => {
            resolve()
        })
    })

    it("checker", async () => {
        let response = await GelatoResolver.checker()
        console.log("responseof checker", response)

        return new Promise(async (resolve) => {
            resolve()
        })
    })

    //0x0eD7e52944161450477ee417DE9Cd3a859b14fD0  //cake bnb lp
})

//functions

const costOfHarvest = async () => {
    let gasEstimation = 533966 // 419310 //533966
    let gasPrice = 7303301330 //6 // 7 //temmp //get price from some oracle;

    let costHarvest = gasEstimation * gasPrice
    let nativeGasToBaseConversionRate = await tokenToBaseTokenConversionRate(
        NATIVE_GAS
    )
    let costOfHarvestBase = nativeGasToBaseConversionRate * costHarvest
    return costOfHarvestBase
}

const getStepwiseH = async (vaultAddress, account) => {
    let vaultAmount = await netCapitalDeposited(vaultAddress, account)
    let cost = await costOfHarvest()
    let x =
        (1 + Math.sqrt(1 + (8 * vaultAmount) / cost)) /
        ((2 * vaultAmount) / cost)
    let H = x * vaultAmount
    return H
}

const getHarvestAmount = async (vaultAddress, account) => {
    const vaultContract = await ethers.getContractAt(
        vaultAbi,
        vaultAddress,
        account
    )

    const strategyContract = await ethers.getContractAt(
        strategyAbi,
        await vaultContract.strategy(),
        account
    )

    const currRewardsAvailable = await strategyContract.rewardsAvailable()
    const rewardToBaseConversionRate = await tokenToBaseTokenConversionRate(
        REWARD
    )
    return currRewardsAvailable * rewardToBaseConversionRate
}

const netCapitalDeposited = async (vaultAddress, account) => {
    const vaultContract = await ethers.getContractAt(
        vaultAbi,
        vaultAddress,
        account
    )
    const netInvestedCapital = await vaultContract.balance()
    const strategyContract = await ethers.getContractAt(
        strategyAbi,
        await vaultContract.strategy(),
        account
    )
    const lpPool = await strategyContract.stake()
    const lpTokenValue = await lpTokenToBaseTokenConversionRate(lpPool, account)
    return lpTokenValue * netInvestedCapital
}

const tokenToBaseTokenConversionRate = async (token, account) => {
    if (token === BASE_CURRENCY) {
        return 1
    }

    const pancakeFactoryContract = await ethers.getContractAt(
        pancakeFactoryAbi,
        PANCAKE_FACTORY,
        account
    )
    const lpAddress = await pancakeFactoryContract.getPair(token, BASE_CURRENCY)
    const lpContract = await ethers.getContractAt(
        pancakePairAbi,
        lpAddress,
        account
    )
    const reserves = await lpContract.getReserves()
    const reserve0 = reserves._reserve0
    const reserve1 = reserves._reserve1

    const [token0, token1] = arrangeTokens(token, BASE_CURRENCY)
    return Math.floor(
        token0 === token ? reserve1 / reserve0 : reserve0 / reserve1
    )
}

const lpTokenToBaseTokenConversionRate = async (lpPool, account) => {
    const lpContract = await ethers.getContractAt(
        pancakePairAbi,
        lpPool,
        account
    )

    const reserves = await lpContract.getReserves()
    const reserve0 = reserves._reserve0
    const reserve1 = reserves._reserve1

    const token0 = await lpContract.token0()
    const token1 = await lpContract.token1()
    const reserve0InBaseToken =
        (await tokenToBaseTokenConversionRate(token0)) * reserve0
    const reserve1InBaseToken =
        (await tokenToBaseTokenConversionRate(token1)) * reserve1
    const lpTotalSuppy = await lpContract.totalSupply()

    return Math.floor(
        (reserve0InBaseToken + reserve1InBaseToken) / lpTotalSuppy
    )
}

const arrangeTokens = (tokenA, tokenB) => {
    return tokenA.toLowerCase() < tokenB.toLowerCase()
        ? [tokenA, tokenB]
        : [tokenB, tokenA]
}

const gelaotoPreSetup = async (account) => {
    let treasuryAddress = "0xbece6a2101ec94e817c072622671b399a3508ac1"
    // await network.provider.send("hardhat_impersonateAccount", [treasuryAddress])
    // //for tojen transfer
    // const treasury = ethers.provider.getSigner(treasuryAddress)
    const treasury = await ethers.getContract(
        "TaskTreasuryUpgradable",
        treasuryAddress
    )
    console.log("treasury", treasury)
    // console.log("treasury", treasury)
    // console.log(PRIVATE_KEY, "private key")
    // let tx = await treasury
    //     // .connect(account)
    //     .depositFunds(
    //         account,
    //         "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    //         35000000000000000000,
    //         { value: 35000000000000000000 }
    //     )
    // await tx.wait()
    // console.log("tx", tx)
}
