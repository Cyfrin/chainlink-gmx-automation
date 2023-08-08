// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {EventLogDecoder} from "./EventLogDecoder.sol";
import {ILogAutomation} from "./chainlink/ILogAutomation.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";

/// @notice Market Decrease Automation
contract MarketDecrease is ILogAutomation {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    error IncorrectEventName(string eventName, string expectedEventName);
    error IncorrectOrderType(uint256 orderType, uint256 expectedOrderType);

    error DataStreamsLookup(string feedLabel, address[] feeds, string queryLabel, uint256 query, bytes data);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE = 4;

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;

    constructor(DataStore dataStore, Reader reader) {
        i_dataStore = dataStore;
        i_reader = reader;
    }

    function checkLog(ILogAutomation.Log calldata log, bytes calldata) external view returns (bool, bytes memory) {
        // Decode Event Log 2
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog2();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        (bytes32 key, address market, uint256 orderType, address[] memory swapPath) = eventData.decodeEventData();

        if (orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE) {
            revert IncorrectOrderType(orderType, EXPECTED_LOG_EVENTDATA_ORDERTYPE);
        }

        address[] memory feedIds = new address[](swapPath.length + 1);
        for (uint256 i = 0; i < feedIds.length; i++) {
            address marketToken;
            if (i == 0) {
                marketToken = i_reader.getMarket(i_dataStore, market).marketToken;
            } else {
                marketToken = i_reader.getMarket(i_dataStore, swapPath[i - 1]).marketToken;
            }
            // TODO: Get FeedId from somewhere using marketToken
            feedIds[i] = marketToken; // TODO: placeholder for now
        }

        string memory feedLabel = "feedIDHex"; // feedLabel can be "feedIDStr" "feedIDHex"
        string memory queryLabel = "BlockNumber"; //queryLabel can be "BlockNumber" or "Timestamp"
        bytes memory data = abi.encode(key);

        revert DataStreamsLookup(feedLabel, feedIds, queryLabel, log.blockNumber, data);
    }

    function oracleCallback(bytes[] calldata values, bytes calldata extraData)
        external
        view
        returns (bool, bytes memory)
    {}

    function performUpkeep(bytes calldata performData) external {}
}
