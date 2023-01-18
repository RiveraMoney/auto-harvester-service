const { task } = require("hardhat/config")

require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const {
    pancakeFactoryAbi,
    riveraFactoryVaultAbi,
    pancakePairAbi,
    strategyAbi,
    vaultAbi,
} = require("./utils/Abis")
require("@nomiclabs/hardhat-ethers")

task("impersonate", "impersonate an account")
    // .addParam("token", "The address of a token")
    // .addParam("tokenwhale", "From address")
    // .addParam("amount", "The amount of token")
    .setAction(async (taskArgs) => {
        // Create the contract instance\
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xAF054349a776e3b8bFf895B5DbD0969E6caeDC33"],
        })
        console.log(
            "impersonated",
            "0xAF054349a776e3b8bFf895B5DbD0969E6caeDC33"
        )
        let acc = await ethers.getSigner(
            "0xAF054349a776e3b8bFf895B5DbD0969E6caeDC33"
        )
        console.log("acc", acc.address)

        const strategyContract = await ethers.getContractAt(
            strategyAbi,
            "0x999FC67056B1eCa6C1c242ecC1900FeDB4CFdf24",
            acc
        )
        console.log("strategyContract", strategyContract.address)
        const currRewardsAvailable = await strategyContract.poolId()
        console.log("currRewardsAvailable", currRewardsAvailable.toString())
    })

task("transferMeTokens", "transfers gelato balance to user")
    // .addParam("token", "The address of a token")
    // .addParam("tokenwhale", "From address")
    // .addParam("amount", "The amount of token")
    .setAction(async (taskArgs) => {
        // Create the contract instance
        const tokenwhale = "0xbd7348a8302d73782be4B4C3E959ECbCAD26FE2D"
        const _tokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        const amount = 35000000000000000000
        accounts = await ethers.getSigners(1)

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [tokenwhale],
        })
        console.log("Impersonating", tokenwhale)
        let whale = await ethers.getSigner(tokenwhale)
        let token = await ethers.getContractAt("IERC20", _tokenAddress)
        console.log(token.address, "token address")
        let tokenwhaleBalance = await token.balanceOf(whale.address)
        console.log(`token balance of whale: ${tokenwhale}`, tokenwhaleBalance)
        // let tx = await token
        //     .connect(whale)
        //     .transfer(await accounts[0].getAddress(), amount)
        // await tx.wait()
        // console.log(
        //     `token balance of user 1: ${await accounts[0].getAddress()}`,
        //     await token.balanceOf(await accounts[0].getAddress())
        // )
    })

const GOERLI_RPC_URL =
    process.env.GOERLI_RPC_URL ||
    "https://eth-mainnet.alchemyapi.io/v2/your-api-key"
const ARBITRUM_RPC_URL =
    process.env.ARBITRUM_RPC_URL ||
    "https://arb-goerli.g.alchemy.com/v2/4XA31P8SHW-ybJyJHf-2Fy31HuFDfF4U"
const PRIVATE_KEY =
    process.env.PRIVATE_KEY ||
    "0x11ee3108a03081fe260ecdc106554d09d9d1209bcafd46942b10e02943effc4a"

module.exports = {
    defaultNetwork: "localhost",
    networks: {
        hardhat: {
            // chainId: 31337,
            // gasPrice: 130000000000,
            forking: {
                url: "https://eth-mainnet.g.alchemy.com/v2/pPIxoT0UCmsseL4KGMY6fMxSyqWjzOIB",
                // url: "http://localhost:8545",
            },
            accounts: {
                mnemonic:
                    "test test test test test test test test test test test junk",
                path: "m/44'/60'/0'/0/",
                initialIndex: 0,
                // count: 20,
                passphrase: "",
            },
            // chainId: 56,
        },
        goerli: {
            url: GOERLI_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 5,
            blockConfirmations: 6,
            gas: 2100000,
            gasPrice: 8000000000,
        },
        arbitrumTestnet: {
            url: ARBITRUM_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 421613,
            blockConfirmations: 1,
            // gas: 2100000,
            // gasPrice: 8000000000,
        },
        localhost: {
            // url: "http://localhost:8545",
            // chainId: 1337,
            // timeout: 100_000,
            // url: "http://127.0.0.1:8545/",
            // chainId: 31337,
            // timeout: 100_000,
            url: "http://127.0.0.1:8545/",
            accounts: {
                mnemonic:
                    "test test test test test test test test test test test junk",
                path: "m/44'/60'/0'/0/",
                initialIndex: 0,
                // count: 20,
                passphrase: "",
            },
            chainId: 56,
            timeout: 100_000,
        },
        ganachebsc: {
            url: "http://localhost:8545",
            chainId: 1337,
            timeout: 100_000,
            // url: "http://127.0.0.1:8545/",
            // chainId: 31337,
            // timeout: 100_000,
            // url: "http://127.0.0.1:8545/",
            // chainId: 56,
            // timeout: 100_000,
        },
    },
    // mocha: {
    //     timeout: 100000000,
    // },
    solidity: {
        compilers: [
            {
                version: "0.7.6",
                settings: {
                    evmVersion: "istanbul",
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                    },
                },
            },
            {
                version: "0.8.8",
                settings: {
                    evmVersion: "istanbul",
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                    },
                },
            },
            {
                version: "0.6.6",
            },
            {
                version: "0.7.0",
                settings: {
                    evmVersion: "istanbul",
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                    },
                },
            },
            // {
            //     version: "0.8.0",
            // },
        ],
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        // coinmarketcap: COINMARKETCAP_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
}
