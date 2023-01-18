const { getNamedAccounts, deployments, network } = require("hardhat")
// const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const _liquidityValue = 100000000
// const _priceFeedeth = "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e" //goerli
// const _priceFeedusdc = "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7" //goerli
// const _EthUsdcPool = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88" ///eth/usdc goerli uniswap pool

const _priceFeedeth = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419" //mainnet eth
const _priceFeedusdc = "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6" //mainnet eth
const _EthUsdcPool = "0x2E8135bE71230c6B1B4045696d41C09Db0414226" ///eth/usdc mainnet pancake arm
console.log("network.name", network.name)

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // const chainId = network.config.chainId
    const GelatoPOC = await deploy("GelatoPOC", {
        from: deployer,
        args: [_liquidityValue, _priceFeedeth, _priceFeedusdc, _EthUsdcPool],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
        // waitConfirmations: 1,
    })
    log(`GelatoPOC deployed at ${GelatoPOC.address}`)
    // const GelatoResolverexample = await deploy("GelatoResolver", {
    //     from: deployer,
    //     args: [GelatoPOC.address],
    //     log: true,
    //     // we need to wait if on a live network so we can verify properly
    //     // waitConfirmations: network.config.blockConfirmations || 1,
    //     waitConfirmations: 1,
    // })
    // log(`GelatoResolverexample deployed at ${GelatoResolverexample.address}`)
}

module.exports.tags = ["all", "GelatoPOC"]
