// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/test.sol";
import {EventLogDecoder} from "../src/EventLogDecoder.sol";
import {ILogAutomation} from "../src/chainlink/ILogAutomation.sol";
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {TestData} from "./TestData.sol";

/// @notice Test the EventLogDecoder.decodeEventLog function
contract EventLogDecoderTest_decodeEventLog is Test, TestData {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    address internal s_msgSender;
    uint256 internal s_blockNumber;
    string internal s_eventName;
    address internal s_market;
    address[] internal s_swapPath;
    bytes32 internal s_key;
    uint256 internal s_orderType;

    ILogAutomation.Log internal s_log;

    function setUp() public {
        s_msgSender = address(44);
        s_blockNumber = 12345;
        s_eventName = "OrderCreated";
        s_market = address(55);
        s_swapPath = new address[](2);
        s_swapPath[0] = address(66);
        s_swapPath[1] = address(77);
        s_key = keccak256("GMX");
        s_orderType = 4;
        s_log = _generateValidLog(
            s_msgSender,
            s_blockNumber,
            EventLogDecoder.EventLog2.selector,
            s_eventName,
            s_market,
            s_swapPath,
            s_key,
            s_orderType
        );
    }

    function test_decodeEventLog_EventLog2_success() public {
        (address returnedMsgSender, string memory returnedEventName,) =
            s_log.decodeEventLog();
        assertEq(returnedMsgSender, s_msgSender);
        assertEq(returnedEventName, s_eventName);
    }

    function test_decodeEventLog_EventLog1_success() public {
        s_log = _generateValidLog(
            s_msgSender,
            s_blockNumber,
            EventLogDecoder.EventLog1.selector,
            s_eventName,
            s_market,
            s_swapPath,
            s_key,
            s_orderType
        );
        (address returnedMsgSender, string memory returnedEventName,) =
            s_log.decodeEventLog();
        assertEq(returnedMsgSender, s_msgSender);
        assertEq(returnedEventName, s_eventName);
    }

    function test_decodeEventLog_IncorrectLogSelector_reverts() public {
        s_log.topics[0] = bytes32(0);
        vm.expectRevert(abi.encodeWithSelector(EventLogDecoder.IncorrectLogSelector.selector, s_log.topics[0]));
        s_log.decodeEventLog();
    }

    function test_decodeEventLog_MalformedEventData_reverts() public {
        s_log.data = abi.encode(s_msgSender, s_eventName, s_market, s_swapPath, s_key, s_orderType);
        vm.expectRevert();
        s_log.decodeEventLog();
    }
}

contract EventLogDecoderTest_RealData is Test, TestData {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    // REAL DATA TESTS
    // Test decoding an event log 2
    function test_decodeEventLog_realData_orderType5() public {
        (address msgSender, string memory eventName,) = _realEventLog2Data_orderType5().decodeEventLog();

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
}
