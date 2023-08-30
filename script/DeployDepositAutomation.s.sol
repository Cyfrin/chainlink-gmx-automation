// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// forge-std
import {Script} from "forge-std/Script.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {DepositHandler} from "gmx-synthetics/exchange/DepositHandler.sol";
// local
import {DepositAutomation} from "../src/DepositAutomation.sol";
import {TestData} from "../test/TestData.sol";

contract DeployDepositAutomation is Script, TestData {
    function run() external returns (DepositAutomation depositAutomation) {
        DataStore dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        Reader reader = Reader(vm.envAddress(READER_LABEL));
        DepositHandler depositHandler = DepositHandler(vm.envAddress(DEPOSIT_HANDLER_LABEL));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        depositAutomation = new DepositAutomation(dataStore, reader, depositHandler);
        vm.stopBroadcast();
    }
}
