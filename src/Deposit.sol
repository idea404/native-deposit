// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {XApp} from "lib/omni/contracts/src/pkg/XApp.sol";
import {ConfLevel} from "lib/omni/contracts/src/libraries/ConfLevel.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {DepositManager} from "./DepositManager.sol";

contract Deposit is XApp, Ownable {
    uint64 public ADD_DEPOSIT_GAS = 200_000; // TODO: profile with testing

    address public manager;

    constructor(address _portal, address _admin, address _managerContract) XApp(_portal, ConfLevel.Finalized) Ownable(_admin) {
        manager = _managerContract;
    }

    function deposit() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Deposit: deposit more than 0");

        uint256 fee = feeFor(
            omni.omniChainId(),
            abi.encodeWithSelector(DepositManager.xDeposit.selector, msg.sender, amount),
            ADD_DEPOSIT_GAS
        );

        require(amount > fee, "Deposit: user xcall gas fee");
        amount -= fee;

        xcall(
            omni.omniChainId(),
            manager,
            abi.encodeWithSelector(DepositManager.xDeposit.selector, msg.sender, amount),
            ADD_DEPOSIT_GAS
        );
    }

    function withdrawTo(address to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Deposit: transfer failed");
    }
}

