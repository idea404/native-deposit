// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {XApp} from "@omni/contracts/src/pkg/XApp.sol";
import {ConfLevel} from "@omni/contracts/src/libraries/ConfLevel.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Deposit} from "./Deposit.sol";

contract DepositManager is XApp, Ownable {
    uint256 public totalDeposit;
    uint256 public constant XRETURN_GAS = 100_000; // TODO: profile with testing

    mapping(uint64 => uint256) public depositOn; // chainId => amount
    mapping(uint64 => address) public contractOn; // chainId => contract address
    mapping(uint64 => bool) public supportedChains; // chainId => is supported
    mapping(uint64 => uint256) public conversionRates; // sourceChainId => conversion rate to global chain native token

    event ConversionRateUpdated(uint256 chainId, uint256 newRate);
    event ChainSupportUpdated(uint256 chainId, bool isSupported);
    event DepositRecorded(address indexed user, uint256 indexed chainId, uint256 amount);

    constructor(address _portal, address _admin) XApp(_portal, ConfLevel.Latest) Ownable(_admin){}

    function setConversionRate(uint64 chainId, uint256 rate) external onlyOwner {
        conversionRates[chainId] = rate;
        emit ConversionRateUpdated(chainId, rate);
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

        uint256 convertedAmount = amount * conversionRates[xmsg.sourceChainId];
        depositOn[xmsg.sourceChainId] += amount;
        totalDeposit += convertedAmount;

        (bool success, ) = user.call{value: convertedAmount}("");
        require(success, "DepositManager: transfer failed"); // TODO: handle failures better

        emit DepositRecorded(user, xmsg.sourceChainId, amount);
    }

    // Function to receive ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
