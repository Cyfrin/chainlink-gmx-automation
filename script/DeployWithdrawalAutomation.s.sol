// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// forge-std
import {Script} from "forge-std/Script.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {WithdrawalHandler} from "gmx-synthetics/exchange/WithdrawalHandler.sol";
// local
import {WithdrawalAutomation} from "../src/WithdrawalAutomation.sol";
import {TestData} from "../test/TestData.sol";

contract DeployWithdrawalAutomation is Script, TestData {
    function run() external returns (WithdrawalAutomation withdrawalAutomation) {
        DataStore dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        Reader reader = Reader(vm.envAddress(READER_LABEL));
        WithdrawalHandler withdrawalHandler = WithdrawalHandler(vm.envAddress(WITHDRAWAL_HANDLER_LABEL));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        withdrawalAutomation = new WithdrawalAutomation(dataStore, reader, withdrawalHandler);
        vm.stopBroadcast();
    }
}