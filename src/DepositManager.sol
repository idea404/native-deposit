// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {XApp} from "lib/omni/contracts/src/pkg/XApp.sol";
import {ConfLevel} from "lib/omni/contracts/src/libraries/ConfLevel.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Deposit} from "./Deposit.sol";

contract DepositManager is XApp, Ownable {
    uint256 public totalDeposit;
    uint256 public constant XRETURN_GAS = 100_000; // TODO: profile with testing

    mapping(uint64 => uint256) public depositOn; // chainId => amount
    mapping(uint64 => address) public contractOn; // chainId => contract address
    mapping(uint64 => bool) public supportedChains; // chainId => is supported
    mapping(uint64 => uint256) public conversionRates; // sourceChainId => conversion rate to global chain native token
    mapping(uint64 => bool) public isHigherValue; // sourceChainId => is the token worth more than the global chain native token

    event ConversionRateUpdated(uint64 chainId, uint256 newRate, bool isHigherValue);
    event ChainSupportUpdated(uint64 chainId, bool isSupported);
    event DepositRecorded(address indexed user, uint64 indexed chainId, uint256 amount);

    constructor(address _portal, address _admin) XApp(_portal, ConfLevel.Finalized) Ownable(_admin) {}

    function setConversionRate(uint64 chainId, uint256 rate, bool higherValue) external onlyOwner {
        conversionRates[chainId] = rate;
        isHigherValue[chainId] = higherValue;
        emit ConversionRateUpdated(chainId, rate, higherValue);
    }

    function updateChainSupport(uint64 chainId, bool isSupported, address contractAddress) external onlyOwner {
        supportedChains[chainId] = isSupported;
        contractOn[chainId] = contractAddress;
        emit ChainSupportUpdated(chainId, isSupported);
    }

    function xDeposit(address user, uint256 amount) external xrecv {
        require(isXCall(), "DepositManager: only xcall");
        require(supportedChains[xmsg.sourceChainId], "DepositManager: chain not supported");
        require(xmsg.sender == contractOn[xmsg.sourceChainId], "DepositManager: invalid sender");

        uint256 convertedAmount;
        if (isHigherValue[xmsg.sourceChainId]) {
            // If the source chain's token is worth more, divide the amount by the rate
            convertedAmount = amount / conversionRates[xmsg.sourceChainId];
        } else {
            // If the source chain's token is worth less or equal, multiply the amount by the rate
            convertedAmount = amount * conversionRates[xmsg.sourceChainId];
        }

        depositOn[xmsg.sourceChainId] += amount;
        totalDeposit += convertedAmount;

        (bool success, ) = user.call{value: convertedAmount}("");
        require(success, "DepositManager: transfer failed"); // can handle failures better

        emit DepositRecorded(user, xmsg.sourceChainId, amount);
    }

    // Function to receive ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
