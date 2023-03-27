const { ethers, network, getNamedAccounts } = require("hardhat")
const { oracleAbi, orderManagerAbi } = require("../utils/Abis")

//constants
const USDC = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
async function TransferUsdc() {
    const { deployer } = await getNamedAccounts()

    await whaleAndApprove(
        "0x4e850C82E0512B4Edcd00F8C993f3fb9dEA3e7e3",
        deployer
    )
}

const whaleAndApprove = async (addr, deployer) => {
    let usdcContract = await ethers.getContractAt("IERC20", USDC)
    let accountToImpersonate = "0xeb25df7c79a85640c4420680461dcdfd91f0dfad"
    await network.provider.send("hardhat_impersonateAccount", [
        accountToImpersonate,
    ])
    //for tojen transfer
    console.log(
        "balance before",
        (await usdcContract.balanceOf(deployer)).toString()
    )
    const whale = ethers.provider.getSigner(accountToImpersonate)
    let usdcAmount = ethers.utils.parseUnits("6", 18)
    console.log("usdcAmount", usdcAmount.toString())
    await usdcContract.connect(whale).transfer(deployer, usdcAmount)

    console.log(
        "balance after",
        (await usdcContract.balanceOf(deployer)).toString()
    )
    await usdcContract.approve(
        addr,
        usdcAmount //"6000000000000000000"
    )
}

TransferUsdc()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
