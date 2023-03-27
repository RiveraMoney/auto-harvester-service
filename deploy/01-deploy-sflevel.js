const { getNamedAccounts, deployments, network } = require("hardhat")

const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
const USDT = "0x55d398326f99059fF775485246999027B3197955"
const OrderManager = "0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b"
const Oracle = "0x04Db83667F5d59FF61fA6BbBD894824B233b3693"
console.log("network.name", network.name)

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // const chainId = network.config.chainId
    const GelatoPOC = await deploy("ShortAndFarm", {
        from: deployer,
        args: [OrderManager],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
        // waitConfirmations: 1,
    })
    log(`GelatoPOC deployed at ${GelatoPOC.address}`)
}

module.exports.tags = ["all", "GelatoPOC"]
