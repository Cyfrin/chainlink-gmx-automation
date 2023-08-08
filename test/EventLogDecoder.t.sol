// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/test.sol";
import {EventLogDecoder} from "../src/EventLogDecoder.sol";
import {ILogAutomation} from "../src/chainlink/ILogAutomation.sol";
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {TestData} from "./TestData.sol";

contract EventLogDecoderTest_RealData is Test, TestData {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    // Test decoding an event log 2
    function test_decodeEventLog_realData_orderType5() public {
        (address msgSender, string memory eventName,) =
            _realEventLog2Data_orderType5().decodeEventLog();

        assertEq(msgSender, 0x51e210dC8391728E2017B2Ec050e40b2f458090e);
        assertEq(eventName, "OrderCreated");
    }

    function test_decodeEventData_realData_orderType5() public {
        (,, EventUtils.EventLogData memory eventData) = _realEventLog2Data_orderType5().decodeEventLog();
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath) = eventData.decodeEventData();
        assertEq(key, 0x464126dfccf7f941b1c81d99fa95f2cf7c27d88ec836f46de62dbf777a5bdab8);
        assertEq(market, 0x47c031236e19d024b42f8AE6780E44A573170703);
        assertEq(orderType, 5);
        for (uint256 i = 0; i < swapPath.length; i++) {
            console.log(swapPath[i]);
        }
    }

    function test_decodeEventData_realData_orderType4() public {
        (,, EventUtils.EventLogData memory eventData) = _realEventLog2Data_orderType4().decodeEventLog();
        console.log(eventData.bytes32Items.items[0].key);
        // (bytes32 key, address market, uint256 orderType, address[] memory swapPath) = eventData.decodeEventData();
        // console.logBytes32(key);
        // console.log(market);
        // console.log(orderType);

    } 
}
