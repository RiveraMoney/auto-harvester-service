const { ethers, network, getNamedAccounts } = require("hardhat")
const { oracleAbi, orderManagerAbi } = require("../utils/Abis")

//constants
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const USDT = "0x55d398326f99059fF775485246999027B3197955"
const OrderManager = "0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b"
const Oracle = "0x04Db83667F5d59FF61fA6BbBD894824B233b3693"

async function GetPositions() {
    const { deployer } = await getNamedAccounts()
    console.log("deployer", deployer)
    const ShortAndFarm = await ethers.getContract("ShortAndFarm")
    console.log("ShortAndFarm", ShortAndFarm.address)

    let tempshortContract = await ethers.getContractAt(
        orderManagerAbi,
        OrderManager,
        deployer
    )
    console.log("tempshortContract", tempshortContract.address)

    let usdtContract = await ethers.getContractAt("IERC20", USDT)
    console.log("usdtContract", usdtContract.address)
    console.log(
        "usdt balance of vault",
        (await usdtContract.balanceOf(ShortAndFarm.address)).toString()
    )

    let vaultOrders = await tempshortContract.getOrders(
        ShortAndFarm.address,
        0,
        5
    )
    // console.log("vaultOrders", vaultOrders.orderIds.toString())
    console.log("vaultOrders", vaultOrders.orderIds.length)
    for (let index = 0; index < vaultOrders.orderIds.length; index++) {
        const element = vaultOrders.orderIds[index].toString()
        let position = await tempshortContract.orders(parseInt(element))
        console.log("position", position)
        let positionDetails = await tempshortContract.requests(
            parseInt(element)
        )
        console.log("positionDetails", positionDetails)
    }
}

GetPositions()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
