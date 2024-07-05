// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {XApp} from "@omni/contracts/src/pkg/XApp.sol";
import {ConfLevel} from "@omni/contracts/src/libraries/ConfLevel.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DepositManager} from "./DepositManager.sol";

contract Deposit is XApp, Ownable {
    address public GLOBAL_MANAGER_CONTRACT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // TODO: update with actual address
    uint256 public ADD_DEPOSIT_GAS = 200_000; // TODO: profile with testing

    constructor(address _portal, address _admin) XApp(_portal, ConfLevel.Latest) Ownable(_admin) {}

    function deposit() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Deposit: deposit more than 0");

        uint256 fee = xcall(
            omni.omniChainId(),
            GLOBAL_MANAGER_CONTRACT,
            abi.encodeWithSelector(DepositManager.xDeposit.selector, msg.sender, amount),
            ADD_DEPOSIT_GAS
        );

        require(msg.value >= fee, "Deposit: user xcall gas fee");
    }

    function withdrawTo(address to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Deposit: transfer failed");
    }
}

