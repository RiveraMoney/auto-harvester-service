const hre = require("hardhat")

export default async function transferMeTokens(taskArgs, hre) {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [taskArgs.tokenwhale],
    })
    console.log("Impersonating", taskArgs.tokenwhale)

    // let whale = await hre.ethers.getSigner(taskArgs.tokenwhale)
    // let token = await hre.ethers.getContractAt("IERC20", taskArgs.token)

    const [user1, user2, user3] = await hre.ethers.getSigners()

    console.log(
        `token balance of whale: ${taskArgs.tokenwhale}`,
        await token.balanceOf(taskArgs.tokenwhale)
    )

    //   let tx = await token.connect(whale).transfer(await user2.getAddress(), taskArgs.amount);
    //   await tx.wait();
    //   console.log(`token balance of user 1: ${await user2.getAddress()}`, await token.balanceOf(await user2.getAddress()));

    //   tx = await token.connect(whale).transfer(await user3.getAddress(), taskArgs.amount);
    //   await tx.wait();
    //   console.log(`token balance of user 2: ${await user3.getAddress()}`, await token.balanceOf(await user3.getAddress()));
}
