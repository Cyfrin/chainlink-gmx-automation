// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {GMXAutomationBase} from "../src/GMXAutomationBase.sol";
import {TestData} from "../test/TestData.sol";
// forge-std
import {Script} from "forge-std/Script.sol";

contract SetForwarderAddress is Script, TestData {
    // TODO: FILL THESE IN BEFORE RUNNING
    address public constant AUTOMATION_CONTRACT = address(0);
    address public constant FORWARDER_ADDRESS = address(0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        GMXAutomationBase(AUTOMATION_CONTRACT).setForwarderAddress(FORWARDER_ADDRESS);
        vm.stopBroadcast();
    }
}
