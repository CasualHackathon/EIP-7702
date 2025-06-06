// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {}

    function run() public {
        // uncomment line below if you want to deploy to anvil (local chain)
        // vm.createSelectFork("anvil");
        vm.startBroadcast();
        counter = new Counter();
        vm.stopBroadcast();

        // you can deploy multichain on a single script by copying lines above and change the chain
    }
}
