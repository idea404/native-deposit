// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DepositManager} from "../src/DepositManager.sol";

contract DepositManagerScript is Script {
    DepositManager public depositManager;

    function setUp() public {}

    function run() public {
        address portal = vm.envAddress("PORTAL_ADDRESS");

        vm.startBroadcast();

        depositManager = new DepositManager(portal, address(this));
        console.log("DepositManager contract address: ", address(depositManager));

        vm.stopBroadcast();
    }
}
