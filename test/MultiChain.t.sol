// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "../src/Deposit.sol";
import "../src/DepositManager.sol";

contract MultiChainTest is Test {
    Deposit public yourContract1;
    DepositManager public yourContract2;
    
    address public fork1;
    address public fork2;

    function setUp() public { // requires omni CLI devnet to be running
        // Create forks for each Anvil instance
        fork1 = vm.createFork("http://localhost:8545");
        fork2 = vm.createFork("http://localhost:8546");

        // Deploy contract on fork1
        vm.selectFork(fork1);
        yourContract1 = new YourContract1();

        // Deploy contract on fork2
        vm.selectFork(fork2);
        yourContract2 = new YourContract2();
    }

    function testInteractionBetweenChains() public {
        // Interact with contract on fork1
        vm.selectFork(fork1);
        yourContract1.someFunction();

        // Interact with contract on fork2
        vm.selectFork(fork2);
        yourContract2.someFunction();

        // You can add more complex interaction logic here
    }
}
