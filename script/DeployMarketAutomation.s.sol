// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// forge-std
import {Script} from "forge-std/Script.sol";
// gmx-synthetics
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {OrderHandler} from "gmx-synthetics/exchange/OrderHandler.sol";
// local
import {MarketAutomation} from "../src/MarketAutomation.sol";
import {TestData} from "../test/TestData.sol";

contract DeployMarketAutomation is Script, TestData {
    function run() external returns (MarketAutomation marketAutomation) {
        DataStore dataStore = DataStore(vm.envAddress(DATA_STORE_LABEL));
        Reader reader = Reader(vm.envAddress(READER_LABEL));
        OrderHandler orderHandler = OrderHandler(vm.envAddress(ORDER_HANDLER_LABEL));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        marketAutomation = new MarketAutomation(dataStore, reader, orderHandler);
        vm.stopBroadcast();
    }
}
