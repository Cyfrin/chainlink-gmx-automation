// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/test.sol";
import {EventLogDecoder} from "../src/EventLogDecoder.sol";
import {ILogAutomation} from "../src/chainlink/ILogAutomation.sol";
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {TestData} from "./TestData.sol";

/// @notice EventLogDecoder.decodeEventLog(log);
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
        vm.expectRevert(abi.encodeWithSelector(EventLogDecoder.EventLogDecoder_IncorrectLogSelector.selector, s_log.topics[0]));
        s_log.decodeEventLog();
    }

    function test_decodeEventLog_MalformedEventData_reverts() public {
        s_log.data = abi.encode(s_msgSender, s_eventName, s_market, s_swapPath, s_key, s_orderType);
        vm.expectRevert();
        s_log.decodeEventLog();
    }
}

/// @notice EventLogDecoder.decodeEventData(eventData);
contract EventLogDecoderTest_decodeEventData is Test, TestData {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    address internal s_market;
    address[] internal s_swapPath;
    bytes32 internal s_key;
    uint256 internal s_orderType;

    function setUp() public {
        s_market = address(55);
        s_swapPath = new address[](2);
        s_swapPath[0] = address(66);
        s_swapPath[1] = address(77);
        s_key = keccak256("GMX");
        s_orderType = 4;
    }

    function test_decodeEventData_success() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath) = eventData.decodeEventData();
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        for (uint256 i = 0; i < swapPath.length; i++) {
            assertEq(swapPath[i], s_swapPath[i]);
        }
    }

    function test_decodeEventData_IncorrectBytes32ItemsLength_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        eventData.bytes32Items.items = new EventUtils.Bytes32KeyValue[](0);
        vm.expectRevert(EventLogDecoder.EventLogDecoder_NoBytes32Items.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_KeyNotFound_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        eventData.bytes32Items.items[0].key = "notKey";
        for (uint256 i = 0; i < eventData.bytes32Items.items.length; i++) {
            if (keccak256(abi.encode(eventData.bytes32Items.items[i].key)) == keccak256(abi.encode(string("key")))) {
                eventData.bytes32Items.items[i].key = "notKey";
                break;
            }
        }
        vm.expectRevert(EventLogDecoder.EventLogDecoder_KeyNotFound.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_IncorrectAddressItemsLength_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        eventData.addressItems.items = new EventUtils.AddressKeyValue[](0);
        vm.expectRevert(EventLogDecoder.EventLogDecoder_NoAddressItems.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_MarketNotFound_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        for (uint256 i = 0; i < eventData.addressItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.addressItems.items[i].key)) == keccak256(abi.encode(string("market")))) {
                eventData.addressItems.items[i].key = "notMarket";
                break;
            }
        }
        vm.expectRevert(EventLogDecoder.EventLogDecoder_MarketNotFound.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_IncorrectUintItemsLength_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        eventData.uintItems.items = new EventUtils.UintKeyValue[](0);
        vm.expectRevert(EventLogDecoder.EventLogDecoder_NoUintItems.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_OrderTypeNotFound_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        for (uint256 i = 0; i < eventData.uintItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.uintItems.items[i].key)) == keccak256(abi.encode(string("orderType")))) {
                eventData.uintItems.items[i].key = "notOrderType";
                break;
            }
        }
        vm.expectRevert(EventLogDecoder.EventLogDecoder_OrderTypeNotFound.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_IncorrectAddressArrayItemsLength_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        eventData.addressItems.arrayItems = new EventUtils.AddressArrayKeyValue[](0);
        vm.expectRevert(EventLogDecoder.EventLogDecoder_NoAddressArrayItems.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_SwapPathNotFound_reverts() public {
        EventUtils.EventLogData memory eventData = _generateValidEventData(s_market, s_swapPath, s_key, s_orderType);
        for (uint256 i = 0; i < eventData.addressItems.arrayItems.length; i++) {
            if (keccak256(abi.encode(eventData.addressItems.arrayItems[i].key)) == keccak256(abi.encode(string("swapPath")))) {
                eventData.addressItems.arrayItems[i].key = "notSwapPath";
                break;
            }
        }
        vm.expectRevert(EventLogDecoder.EventLogDecoder_SwapPathNotFound.selector);
        eventData.decodeEventData();
    }

    function test_decodeEventData_emptyStruct_reverts() public {
        EventUtils.EventLogData memory eventData;
        vm.expectRevert(EventLogDecoder.EventLogDecoder_NoBytes32Items.selector);
        eventData.decodeEventData();
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
