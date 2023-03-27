const { ethers, network, getNamedAccounts } = require("hardhat")
const { oracleAbi, orderManagerAbi } = require("../utils/Abis")

//constants
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const USDT = "0x55d398326f99059fF775485246999027B3197955"
const OrderManager = "0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b"
const Oracle = "0x04Db83667F5d59FF61fA6BbBD894824B233b3693"
const USDC = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"

async function PlaceOrder() {
    const { deployer } = await getNamedAccounts()
    const ShortAndFarm = await ethers.getContract("ShortAndFarm")
    console.log("ShortAndFarm", ShortAndFarm.address)

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

    let data = await getbytesDataDecrease(
        {
            price: price.toString(),
            payToken: "0x55d398326f99059fF775485246999027B3197955",
            sizeChange: "17946170487547466484828114922500",
            collateral: "5982053829512452533515171885078",
        },
        deployer // ShortLevel.address
    )
    console.log("data", data)
    let tx = await ShortAndFarm.depositTokens(
        ethers.utils.parseUnits("6", 18),
        data,
        1,
        { value: "2500000000000000" }
    )

    await tx.wait()
    console.log("tx", tx)
}

const getbytesDataDecrease = async (order, account) => {
    const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "address", "uint256", "uint256", "bytes"],
        [
            order.price,
            order.payToken,
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
