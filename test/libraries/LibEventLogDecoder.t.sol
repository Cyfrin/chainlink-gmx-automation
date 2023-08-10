// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TestData} from "../TestData.sol";
import {LibEventLogDecoder} from "../../src/libraries/LibEventLogDecoder.sol";
import {ILogAutomation} from "../../src/chainlink/ILogAutomation.sol";
// forge-std
import {Test, console} from "forge-std/test.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";

/// TEST FILE STRUCTURE
/// -------------------
/// Each function in the target conrtact has it's own test contract in this file.
///
/// - `contract LibEventLogDecoderTest_decodeEventLog` -> LibEventLogDecoder.decodeEventLog(log)
/// - `contract LibEventLogDecoderTest_decodeEventData` -> LibEventLogDecoder.decodeEventData(eventData)
/// - `contract LibEventLogDecoderTest_RealData` -> Real data tests

/// @notice LibEventLogDecoder.decodeEventLog(log);
contract LibEventLogDecoderTest_decodeEventLog is Test, TestData {
    using LibEventLogDecoder for ILogAutomation.Log;
    using LibEventLogDecoder for EventUtils.EventLogData;

    address internal s_msgSender;
    uint256 internal s_blockNumber;
    string internal s_eventName;
    address internal s_market;
    address[] internal s_swapPath;
    address[] internal s_longTokenSwapPath;
    address[] internal s_shortTokenSwapPath;
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
        s_longTokenSwapPath = new address[](2);
        s_longTokenSwapPath[0] = address(88);
        s_longTokenSwapPath[1] = address(99);
        s_shortTokenSwapPath = new address[](2);
        s_shortTokenSwapPath[0] = address(111);
        s_shortTokenSwapPath[1] = address(122);
        s_key = keccak256("GMX");
        s_orderType = 4;
        s_log = _generateValidLog(
            s_msgSender,
            s_blockNumber,
            LibEventLogDecoder.EventLog2.selector,
            s_eventName,
            s_market,
            s_swapPath,
            s_key,
            s_orderType,
            s_longTokenSwapPath,
            s_shortTokenSwapPath
        );
    }

    /////////////
    // UNIT TESTS
    /////////////

    function test_decodeEventLog_EventLog2_success() public {
        (address returnedMsgSender, string memory returnedEventName, EventUtils.EventLogData memory eventData) =
            s_log.decodeEventLog();
        assertEq(returnedMsgSender, s_msgSender);
        assertEq(returnedEventName, s_eventName);
        _assertEqualEventData(
            eventData, s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath
        );
    }

    function test_decodeEventLog_EventLog1_success() public {
        s_log = _generateValidLog(
            s_msgSender,
            s_blockNumber,
            LibEventLogDecoder.EventLog1.selector,
            s_eventName,
            s_market,
            s_swapPath,
            s_key,
            s_orderType,
            s_longTokenSwapPath,
            s_shortTokenSwapPath
        );
        (address returnedMsgSender, string memory returnedEventName, EventUtils.EventLogData memory eventData) =
            s_log.decodeEventLog();
        assertEq(returnedMsgSender, s_msgSender);
        assertEq(returnedEventName, s_eventName);
        _assertEqualEventData(
            eventData, s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath
        );
    }

    function test_decodeEventLog_IncorrectLogSelector_reverts() public {
        s_log.topics[0] = bytes32(0);
        vm.expectRevert(
            abi.encodeWithSelector(LibEventLogDecoder.LibEventLogDecoder_IncorrectLogSelector.selector, s_log.topics[0])
        );
        s_log.decodeEventLog();
    }

    function test_decodeEventLog_MalformedEventData_reverts() public {
        s_log.data = abi.encode(s_msgSender, s_eventName, s_market, s_swapPath, s_key, s_orderType);
        vm.expectRevert();
        s_log.decodeEventLog();
    }

    /////////////
    // FUZZ TESTS
    /////////////

    function test_fuzz_decodeEventLog(
        address msgSender,
        uint256 blockNumber,
        bool logSelectorIndex,
        string memory eventName,
        address market,
        address[] memory swapPath,
        bytes32 key,
        uint256 orderType,
        address[] memory longTokenSwapPath,
        address[] memory shortTokenSwapPath
    ) public {
        bytes32 logSelector =
            logSelectorIndex ? LibEventLogDecoder.EventLog1.selector : LibEventLogDecoder.EventLog2.selector;
        s_log = _generateValidLog(
            msgSender,
            blockNumber,
            logSelector,
            eventName,
            market,
            swapPath,
            key,
            orderType,
            longTokenSwapPath,
            shortTokenSwapPath
        );
        (address returnedMsgSender, string memory returnedEventName, EventUtils.EventLogData memory eventData) =
            s_log.decodeEventLog();
        assertEq(returnedMsgSender, msgSender);
        assertEq(returnedEventName, eventName);
        _assertEqualEventData(eventData, market, swapPath, key, orderType, longTokenSwapPath, shortTokenSwapPath);
    }

    ////////
    // UTILS
    ////////

    function _assertEqualEventData(
        EventUtils.EventLogData memory eventData,
        address market,
        address[] memory swapPath,
        bytes32 key,
        uint256 orderType,
        address[] memory longTokenSwapPath,
        address[] memory shortTokenSwapPath
    ) private {
        bool keyFound;
        for (uint256 i = 0; i < eventData.bytes32Items.items.length; i++) {
            if (keccak256(abi.encode(eventData.bytes32Items.items[i].key)) == keccak256(abi.encode(string("key")))) {
                keyFound = true;
                assertEq(eventData.bytes32Items.items[i].value, key);
                break;
            }
        }
        assertTrue(keyFound);
        bool marketFound;
        for (uint256 i = 0; i < eventData.addressItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.addressItems.items[i].key)) == keccak256(abi.encode(string("market")))) {
                marketFound = true;
                assertEq(eventData.addressItems.items[i].value, market);
                break;
            }
        }
        assertTrue(marketFound);
        bool orderTypeFound;
        for (uint256 i = 0; i < eventData.uintItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.uintItems.items[i].key)) == keccak256(abi.encode(string("orderType")))) {
                orderTypeFound = true;
                assertEq(eventData.uintItems.items[i].value, orderType);
                break;
            }
        }
        assertTrue(orderTypeFound);
        bool swapPathFound;
        bool longTokenSwapPathFound;
        bool shortTokenSwapPathFound;
        for (uint256 i = 0; i < eventData.addressItems.arrayItems.length; i++) {
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("swapPath")))
            ) {
                swapPathFound = true;
                assertEq(eventData.addressItems.arrayItems[i].value.length, swapPath.length);
                for (uint256 j = 0; j < eventData.addressItems.arrayItems[i].value.length; j++) {
                    assertEq(eventData.addressItems.arrayItems[i].value[j], swapPath[j]);
                }
            }
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("longTokenSwapPath")))
            ) {
                longTokenSwapPathFound = true;
                assertEq(eventData.addressItems.arrayItems[i].value.length, longTokenSwapPath.length);
                for (uint256 j = 0; j < eventData.addressItems.arrayItems[i].value.length; j++) {
                    assertEq(eventData.addressItems.arrayItems[i].value[j], longTokenSwapPath[j]);
                }
            }
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("shortTokenSwapPath")))
            ) {
                shortTokenSwapPathFound = true;
                assertEq(eventData.addressItems.arrayItems[i].value.length, shortTokenSwapPath.length);
                for (uint256 j = 0; j < eventData.addressItems.arrayItems[i].value.length; j++) {
                    assertEq(eventData.addressItems.arrayItems[i].value[j], shortTokenSwapPath[j]);
                }
            }
        }
        assertTrue(swapPathFound && longTokenSwapPathFound && shortTokenSwapPathFound);
    }
}

/// @notice LibEventLogDecoder.decodeEventData(eventData);
contract LibEventLogDecoderTest_decodeEventData is Test, TestData {
    using LibEventLogDecoder for ILogAutomation.Log;
    using LibEventLogDecoder for EventUtils.EventLogData;

    address internal s_market;
    address[] internal s_swapPath;
    bytes32 internal s_key;
    uint256 internal s_orderType;
    address[] internal s_longTokenSwapPath;
    address[] internal s_shortTokenSwapPath;

    function setUp() public {
        s_market = address(55);
        s_swapPath = new address[](2);
        s_swapPath[0] = address(66);
        s_swapPath[1] = address(77);
        s_longTokenSwapPath = new address[](2);
        s_longTokenSwapPath[0] = address(88);
        s_longTokenSwapPath[1] = address(99);
        s_shortTokenSwapPath = new address[](2);
        s_shortTokenSwapPath[0] = address(111);
        s_shortTokenSwapPath[1] = address(122);
        s_key = keccak256("GMX");
        s_orderType = 4;
    }

    /////////////
    // UNIT TESTS
    /////////////

    function test_decodeEventData_success() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_keyNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.bytes32Items.items.length; i++) {
            if (keccak256(abi.encode(eventData.bytes32Items.items[i].key)) == keccak256(abi.encode(string("key")))) {
                eventData.bytes32Items.items[i].key = "notKey";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(key, bytes32(0));
        // normal values
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_keyNotFound_emptyItems_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        eventData.bytes32Items.items = new EventUtils.Bytes32KeyValue[](0);
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(key, bytes32(0));
        // normal values
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_marketNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.addressItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.addressItems.items[i].key)) == keccak256(abi.encode(string("market")))) {
                eventData.addressItems.items[i].key = "notMarket";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(market, address(0));
        // normal values
        assertEq(key, s_key);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_marketNotFound_emptyItems_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        eventData.addressItems.items = new EventUtils.AddressKeyValue[](0);
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(market, address(0));
        // normal values
        assertEq(key, s_key);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_orderTypeNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.uintItems.items.length; i++) {
            if (keccak256(abi.encode(eventData.uintItems.items[i].key)) == keccak256(abi.encode(string("orderType")))) {
                eventData.uintItems.items[i].key = "notOrderType";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(orderType, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_orderTypeNotFound_emptyItems_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        eventData.uintItems.items = new EventUtils.UintKeyValue[](0);
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(orderType, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(swapPath.length, s_swapPath.length);
        _assertArraysEqualStorage(swapPath, longTokenSwapPath, shortTokenSwapPath);
    }

    function test_decodeEventData_swapPathNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.addressItems.arrayItems.length; i++) {
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("swapPath")))
            ) {
                eventData.addressItems.arrayItems[i].key = "notSwapPath";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(swapPath.length, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(longTokenSwapPath.length, s_longTokenSwapPath.length);
        for (uint256 i = 0; i < longTokenSwapPath.length; i++) {
            assertEq(longTokenSwapPath[i], s_longTokenSwapPath[i]);
        }
        assertEq(shortTokenSwapPath.length, s_shortTokenSwapPath.length);
        for (uint256 i = 0; i < shortTokenSwapPath.length; i++) {
            assertEq(shortTokenSwapPath[i], s_shortTokenSwapPath[i]);
        }
    }

    function test_decodeEventData_longTokenSwapPathNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.addressItems.arrayItems.length; i++) {
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("longTokenSwapPath")))
            ) {
                eventData.addressItems.arrayItems[i].key = "notLongTokenSwapPath";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(longTokenSwapPath.length, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        for (uint256 i = 0; i < swapPath.length; i++) {
            assertEq(swapPath[i], s_swapPath[i]);
        }
        assertEq(shortTokenSwapPath.length, s_shortTokenSwapPath.length);
        for (uint256 i = 0; i < shortTokenSwapPath.length; i++) {
            assertEq(shortTokenSwapPath[i], s_shortTokenSwapPath[i]);
        }
    }

    function test_decodeEventData_shortTokenSwapPathNotFound_doesntExist_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        for (uint256 i = 0; i < eventData.addressItems.arrayItems.length; i++) {
            if (
                keccak256(abi.encode(eventData.addressItems.arrayItems[i].key))
                    == keccak256(abi.encode(string("shortTokenSwapPath")))
            ) {
                eventData.addressItems.arrayItems[i].key = "notShortTokenSwapPath";
                break;
            }
        }
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(shortTokenSwapPath.length, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
        assertEq(swapPath.length, s_swapPath.length);
        for (uint256 i = 0; i < swapPath.length; i++) {
            assertEq(swapPath[i], s_swapPath[i]);
        }
        assertEq(longTokenSwapPath.length, s_longTokenSwapPath.length);
        for (uint256 i = 0; i < longTokenSwapPath.length; i++) {
            assertEq(longTokenSwapPath[i], s_longTokenSwapPath[i]);
        }
    }

    function test_decodeEventData_addressItems_emptyArrayItems_returnsZeroValue() public {
        EventUtils.EventLogData memory eventData =
            _generateValidEventData(s_market, s_swapPath, s_key, s_orderType, s_longTokenSwapPath, s_shortTokenSwapPath);
        eventData.addressItems.arrayItems = new EventUtils.AddressArrayKeyValue[](0);
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero value
        assertEq(swapPath.length, uint256(0));
        assertEq(longTokenSwapPath.length, uint256(0));
        assertEq(shortTokenSwapPath.length, uint256(0));
        // normal values
        assertEq(key, s_key);
        assertEq(market, s_market);
        assertEq(orderType, s_orderType);
    }

    function test_decodeEventData_emptyStruct_returnsZeroValues() public {
        EventUtils.EventLogData memory eventData;
        (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        ) = eventData.decodeEventData();
        // zero values
        assertEq(key, bytes32(0));
        assertEq(market, address(0));
        assertEq(orderType, uint256(0));
        assertEq(swapPath.length, uint256(0));
        assertEq(longTokenSwapPath.length, uint256(0));
        assertEq(shortTokenSwapPath.length, uint256(0));
    }

    /////////////
    // UTILS
    /////////////

    function _assertArraysEqualStorage(
        address[] memory swapPath,
        address[] memory longTokenSwapPath,
        address[] memory shortTokenSwapPath
    ) private {
        assertEq(swapPath.length, s_swapPath.length);
        for (uint256 i = 0; i < swapPath.length; i++) {
            assertEq(swapPath[i], s_swapPath[i]);
        }
        assertEq(longTokenSwapPath.length, s_longTokenSwapPath.length);
        for (uint256 i = 0; i < longTokenSwapPath.length; i++) {
            assertEq(longTokenSwapPath[i], s_longTokenSwapPath[i]);
        }
        assertEq(shortTokenSwapPath.length, s_shortTokenSwapPath.length);
        for (uint256 i = 0; i < shortTokenSwapPath.length; i++) {
            assertEq(shortTokenSwapPath[i], s_shortTokenSwapPath[i]);
        }
    }
}

contract LibEventLogDecoderTest_RealData is Test, TestData {
    using LibEventLogDecoder for ILogAutomation.Log;
    using LibEventLogDecoder for EventUtils.EventLogData;

    // REAL DATA TESTS
    // Test decoding an event log 2
    function test_decodeEventLog_realData_orderType5() public {
        (address msgSender, string memory eventName,) = _realEventLog2Data_orderType5().decodeEventLog();

        assertEq(msgSender, 0x51e210dC8391728E2017B2Ec050e40b2f458090e);
        assertEq(eventName, "OrderCreated");
    }

    function test_decodeEventData_realData_orderType5() public {
        (,, EventUtils.EventLogData memory eventData) = _realEventLog2Data_orderType5().decodeEventLog();
        (bytes32 key, address market, uint256 orderType,,,) = eventData.decodeEventData();
        assertEq(key, 0x464126dfccf7f941b1c81d99fa95f2cf7c27d88ec836f46de62dbf777a5bdab8);
        assertEq(market, 0x47c031236e19d024b42f8AE6780E44A573170703);
        assertEq(orderType, 5);
    }
}
