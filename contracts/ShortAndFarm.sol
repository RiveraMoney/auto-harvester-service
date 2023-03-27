// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IOrderManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract ShortAndFarm {
    IOrderManager public OrderManager;
    address public constant CakeToken =
        0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Cake mainnet
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; //BUSD mainnet

    enum UpdatePositionType {
        INCREASE,
        DECREASE
    }

    constructor(IOrderManager _OrderManager) {
        OrderManager = _OrderManager; //0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b
    }

    function depositTokens(
        uint256 _amount,
        bytes memory data,
        UpdatePositionType _updateType
    ) public payable {
        require(_amount > 0);
        bool isIncrease = _updateType == UpdatePositionType.INCREASE;

        // OrderManager.placeOrder(0, 1, CakeToken, USDT, 0, data);
        if (isIncrease) {
            TransferHelper.safeTransferFrom(
                USDT,
                msg.sender,
                address(this),
                _amount
            );

            TransferHelper.safeApprove(USDT, address(OrderManager), _amount);
            (bool success, ) = address(OrderManager).call{value: msg.value}(
                abi.encodeWithSignature(
                    "placeOrder(uint8,uint8,address,address,uint8,bytes)",
                    0,
                    1,
                    CakeToken,
                    USDT,
                    0,
                    data
                )
            );
            require(success, "OrderManager.placeOrder failed");
        } else {
            (bool success, ) = address(OrderManager).call{value: msg.value}(
                abi.encodeWithSignature(
                    "placeOrder(uint8,uint8,address,address,uint8,bytes)",
                    1,
                    1,
                    CakeToken,
                    USDT,
                    0,
                    data
                )
            );
            require(success, "OrderManager.placeOrder failed");
        }
    }
}
