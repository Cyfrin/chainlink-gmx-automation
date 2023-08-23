// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";

/// @title Event Log Decoder
/// @author Alex Roan - Cyfrin (@alexroan)
library LibGMXEventLogDecoder {
    error LibGMXEventLogDecoder_IncorrectLogSelector(bytes32 logSelector);

    //////////
    // EVENTS
    //////////

    // Logs from gmx-synthetics/event/EventEmitter.sol
    // 0x137a44067c8961cd7e1d876f4754a5a3a75989b4552f1843fc69c3b372def160
    event EventLog1(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        EventUtils.EventLogData eventData
    );

    // 0x468a25a7ba624ceea6e540ad6f49171b52495b648417ae91bca21676d8a24dc5
    event EventLog2(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        EventUtils.EventLogData eventData
    );

    /////////////
    // FUNCTIONS
    /////////////

    /// @notice Decode an EventLog1 or EventLog2 event from a Log
    /// @dev This function reverts if the log is not an EventLog1 or EventLog2 event
    /// @dev We only decode non-indexed data from the log here, hence why eventNameHash, topic1 (and topic2) is not returned.
    /// @param log the log to decode
    /// @return msgSender the sender of the transaction that emitted the log
    /// @return eventName the name of the event
    /// @return eventData the EventUtils EventLogData struct
    function decodeEventLog(Log memory log)
        internal
        pure
        returns (address msgSender, string memory eventName, EventUtils.EventLogData memory eventData)
    {
        // Ensure that the log is an EventLog1 or EventLog2 event
        if (log.topics[0] != EventLog1.selector && log.topics[0] != EventLog2.selector) {
            revert LibGMXEventLogDecoder_IncorrectLogSelector(log.topics[0]);
        }

        (msgSender, eventName, eventData) = abi.decode(log.data, (address, string, EventUtils.EventLogData));
    }

    /// @notice Retrieve the key, market, orderType, swapPath, longTokenSwapPath and shortTokenSwapPath from the EventUtils EventLogData struct
    /// @param eventData the EventUtils EventLogData struct
    /// @return key the key
    /// @return market the market
    /// @return orderType the orderType
    /// @return swapPath the swapPath
    /// @return longTokenSwapPath the longTokenSwapPath
    /// @return shortTokenSwapPath the shortTokenSwapPath
    function decodeEventData(EventUtils.EventLogData memory eventData)
        internal
        pure
        returns (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        )
    {
        // Get the key from the eventData bytes32 items
        EventUtils.Bytes32KeyValue[] memory bytes32Items = eventData.bytes32Items.items;
        for (uint256 i = 0; i < bytes32Items.length; i++) {
            if (keccak256(abi.encode(bytes32Items[i].key)) == keccak256(abi.encode("key"))) {
                key = bytes32Items[i].value;
                break;
            }
        }

        // Extract the market from the event data address items
        EventUtils.AddressKeyValue[] memory addressItems = eventData.addressItems.items;
        for (uint256 i = 0; i < addressItems.length; i++) {
            if (keccak256(abi.encode(addressItems[i].key)) == keccak256(abi.encode("market"))) {
                market = addressItems[i].value;
                break;
            }
        }

        // Extract the orderType from the event data uint items
        EventUtils.UintKeyValue[] memory uintItems = eventData.uintItems.items;
        for (uint256 i = 0; i < uintItems.length; i++) {
            if (keccak256(abi.encode(uintItems[i].key)) == keccak256(abi.encode("orderType"))) {
                orderType = uintItems[i].value;
                break;
            }
        }

        // Extract the swapPath, longTokenSwapPath and shortTokenSwapPath from the event data address array items
        EventUtils.AddressArrayKeyValue[] memory addressArrayItems = eventData.addressItems.arrayItems;
        for (uint256 i = 0; i < addressArrayItems.length; i++) {
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("swapPath"))) {
                swapPath = addressArrayItems[i].value;
            }
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("longTokenSwapPath"))) {
                longTokenSwapPath = addressArrayItems[i].value;
            }
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("shortTokenSwapPath"))) {
                shortTokenSwapPath = addressArrayItems[i].value;
            }
        }
    }
}
