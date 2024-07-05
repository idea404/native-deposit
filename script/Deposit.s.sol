// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Deposit} from "../src/Deposit.sol";

contract DepositScript is Script {
    Deposit public deposit;

    function setUp() public {}

    function run() public {
        address portal = vm.envAddress("PORTAL_ADDRESS");
        address manager = vm.envAddress("DEPOSIT_MANAGER_ADDRESS");

        vm.startBroadcast();

        deposit = new Deposit(portal, address(this), manager);
        console.log("Deposit contract address: ", address(deposit));

        vm.stopBroadcast();
    }
}
