const { ethers, network, getNamedAccounts } = require("hardhat")
const { oracleAbi, orderManagerAbi } = require("../utils/Abis")

//constants
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const USDT = "0x55d398326f99059fF775485246999027B3197955"
const OrderManager = "0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b"
const Oracle = "0x04Db83667F5d59FF61fA6BbBD894824B233b3693"

async function PlaceOrder() {
    const { deployer } = await getNamedAccounts()
    const ShortAndFarm = await ethers.getContract("ShortAndFarm")
    console.log("ShortAndFarm", ShortAndFarm.address)

    await whaleAndApprove(ShortAndFarm, deployer)

    //getcakeprice
    let OracleContract = await ethers.getContractAt(
        oracleAbi,
        Oracle,
        deployer
        // whale
    )
    console.log("OracleContract", OracleContract.address)
    price = await OracleContract.getLastPrice(CAKE)
    console.log("price", price.toString())

    let data = await getbytesDataIncrease(
        {
            price: price.toString(),
            purchaseToken: "0x55d398326f99059fF775485246999027B3197955",
            purchaseAmount: "6000000000000000000",
            sizeChange: "17946170487547466484828114922500",
            collateral: "6000000000000000000",
        },
        deployer // ShortLevel.address
    )
    console.log("data", data)
    let tx = await ShortAndFarm.depositTokens(
        ethers.utils.parseUnits("6", 18),
        data,
        0,
        { value: "3500000000000000" }
    )

    await tx.wait()
    console.log("tx", tx)
}

const whaleAndApprove = async (ShortAndFarm, deployer) => {
    let usdtContract = await ethers.getContractAt("IERC20", USDT)
    let accountToImpersonate = "0xc686d5a4a1017bc1b751f25ef882a16ab1a81b63"
    await network.provider.send("hardhat_impersonateAccount", [
        accountToImpersonate,
    ])
    //for tojen transfer
    console.log(
        "balance before",
        (await usdtContract.balanceOf(deployer)).toString()
    )
    const whale = ethers.provider.getSigner(accountToImpersonate)
    let usdtAmount = ethers.utils.parseUnits("6", 18)
    console.log("usdtAmount", usdtAmount.toString())
    await usdtContract.connect(whale).transfer(deployer, usdtAmount)

    console.log(
        "balance after",
        (await usdtContract.balanceOf(deployer)).toString()
    )
    await usdtContract.approve(
        ShortAndFarm.address, //"0x6498EF40C8C6c5B4466F8943Cc470B7c67A0B331",
        usdtAmount //"6000000000000000000"
    )
}

const getbytesDataIncrease = async (order, account) => {
    const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "address", "uint256", "uint256", "uint256", "bytes"],
        [
            order.price,
            order.purchaseToken,
            order.purchaseAmount,
            order.sizeChange,
            order.collateral,
            // defaultAbiCoder.encode(["address"], [account]),
            "0x0000000000000000000000000000000000000000000000000000000000000000",
        ]
    )
    // console.log("data", data)
    return data
}

PlaceOrder()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
