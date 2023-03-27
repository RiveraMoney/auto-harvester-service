const { expect, assert } = require("chai")
const { defaultAbiCoder } = require("ethers/lib/utils")
const { ethers, network } = require("hardhat")
// require("@nomiclabs/hardhat-ethers")
const { oracleAbi, orderManagerAbi } = require("../../utils/Abis")

//constants
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const USDT = "0x55d398326f99059fF775485246999027B3197955"
const OrderManager = "0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b"
const Oracle = "0x04Db83667F5d59FF61fA6BbBD894824B233b3693"
// const PRIVATE_KEY = process.env.PRIVATE_KEY

describe("SHortLevel", () => {
    let accounts, ShortLevel, OracleContract, price, usdtContract, cakeContract

    // let provider = new ethers.providers.JsonRpcProvider(network.config.url)

    before(async () => {
        accounts = await ethers.getSigners(1)
        const chainId = network.config.chainId
        console.log("chainid", chainId)
        // console.log("accounts", accounts[0])

        cakeContract = await ethers.getContractAt("IERC20", CAKE)
        usdtContract = await ethers.getContractAt("IERC20", USDT)

        let accountToImpersonate = "0xc686d5a4a1017bc1b751f25ef882a16ab1a81b63"
        await network.provider.send("hardhat_impersonateAccount", [
            accountToImpersonate,
        ])
        //for tojen transfer
        console.log(
            "balance before",
            (await usdtContract.balanceOf(accounts[0].address)).toString()
        )
        const whale = ethers.provider.getSigner(accountToImpersonate)
        let usdtAmount = ethers.utils.parseUnits("6", 18)
        console.log("usdtAmount", usdtAmount.toString())
        await usdtContract
            .connect(whale)
            .transfer(accounts[0].address, usdtAmount)

        console.log(
            "balance after",
            (await usdtContract.balanceOf(accounts[0].address)).toString()
        )

        //end token tranfes

        //Deplloy Gelato
        const shortLevel = await ethers.getContractFactory("ShortAndFarm")
        ShortLevel = await shortLevel.deploy(OrderManager)
        await ShortLevel.deployed()
        console.log("ShortLevel  deployed to:", ShortLevel.address)

        //Approve vault to spend cake token
        await usdtContract.approve(
            ShortLevel.address, //"0x6498EF40C8C6c5B4466F8943Cc470B7c67A0B331",
            usdtAmount //"6000000000000000000"
        )

        //getcakeprice
        OracleContract = await ethers.getContractAt(
            oracleAbi,
            Oracle,
            accounts[0]
            // whale
        )
        console.log("OracleContract", OracleContract.address)
        price = await OracleContract.getLastPrice(CAKE)
        console.log("price", price.toString())
    })

    it("place order", async () => {
        let data = await getbytesDataIncrease(
            {
                price: price.toString(),
                purchaseToken: "0x55d398326f99059fF775485246999027B3197955",
                purchaseAmount: "6000000000000000000",
                sizeChange: "17946170487547466484828114922500",
                collateral: "6000000000000000000",
            },
            accounts[0] // ShortLevel.address
        )
        console.log("data", data)
        // let tx = await ShortLevel.depositTokens(
        //     ethers.utils.parseUnits("6", 18),
        //     data
        // )
        //Working below code
        let tx = await ShortLevel.depositTokens(
            ethers.utils.parseUnits("6", 18),
            data,
            0,
            { value: "3500000000000000" }
        )

        await tx.wait()
        console.log("tx", tx)

        // done()
        return new Promise((resolve) => {
            resolve()
        })
    })
    it("get position", async () => {
        let tempshortContract = await ethers.getContractAt(
            orderManagerAbi,
            OrderManager,
            accounts[0]
        )
        let userOrders = await tempshortContract.getOrders(
            ShortLevel.address,
            0,
            5
        )
        console.log("userOrders", userOrders.toString())
        let id = await tempshortContract.userOrders(ShortLevel.address, 0)
        console.log("id", id.toString())

        let position = await tempshortContract.orders(id)
        console.log("position", position)

        // done()
        return new Promise((resolve) => {
            resolve()
        })
    })
    it("close position", async () => {
        let data = await getbytesDataDecrease(
            {
                price: price.toString(),
                payToken: "0x55d398326f99059fF775485246999027B3197955",
                sizeChange: "17946170487547466484828114922500",
                collateral: "5982053829512452533515171885078",
            },
            accounts[0] // ShortLevel.address
        )
        console.log("data", data)

        let tx = await ShortLevel.depositTokens(
            ethers.utils.parseUnits("6", 18),
            data,
            1,
            { value: "3500000000000000" }
        )

        await tx.wait()
        console.log("tx", tx)

        // done()
        return new Promise((resolve) => {
            resolve()
        })
    })

    //0x0eD7e52944161450477ee417DE9Cd3a859b14fD0  //cake bnb lp
})

//functions

const getbytesDataIncrease = async (order, account) => {
    const data = defaultAbiCoder.encode(
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
    console.log("data", data)
    return data
}

const getbytesDataDecrease = async (order, account) => {
    const data = defaultAbiCoder.encode(
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
    console.log("data", data)
    return data
}
