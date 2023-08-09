// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {EventLogDecoder} from "./EventLogDecoder.sol";
import {ILogAutomation} from "./chainlink/ILogAutomation.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";

// TODO: withdraw function to pull the native token from this contract

/// @notice Market Decrease Automation
contract MarketDecrease is ILogAutomation {
    using EventLogDecoder for ILogAutomation.Log;
    using EventLogDecoder for EventUtils.EventLogData;

    // ERRORS
    error IncorrectEventName(string eventName, string expectedEventName);
    error IncorrectOrderType(uint256 orderType, uint256 expectedOrderType);
    error DataStreamsLookup(string feedLabel, address[] feeds, string queryLabel, uint256 query, bytes data);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    // TODO: Use checkData instead of this
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE = 4;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "BlockNumber";

    // IMMUTABLES
    DataStore public immutable i_dataStore;
    Reader public immutable i_reader;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    constructor(DataStore dataStore, Reader reader) {
        i_dataStore = dataStore;
        i_reader = reader;
    }

    /// @notice Retrieve relevant information from the log and perform a data streams lookup
    /// @dev Reverts with custom errors if the event name is not equal to the expected event name (OrderCreated), or if the orderType is not equal to the expected orderType (4)
    /// @dev In the success case, reverts with DataStreamsLookup error containing relevant information for the data streams lookup
    function checkLog(ILogAutomation.Log calldata log, bytes calldata checkData) external view returns (bool, bytes memory) {
        // Decode Event Log 2
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath) = eventData.decodeEventData();

        // Revert if the orderType is not equal to the expected orderType
        if (orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE) {
            revert IncorrectOrderType(orderType, EXPECTED_LOG_EVENTDATA_ORDERTYPE);
        }

        // For each address in the market and swapPath array, retrieve the Props struct from the DataStore
        // and use the marketToken to retrieve the feedId
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

        // Construct the data for the data streams lookup error
        revert DataStreamsLookup(STRING_DATASTREAMS_FEEDLABEL, feedIds, STRING_DATASTREAMS_QUERYLABEL, log.blockNumber, abi.encode(key));
    }

    // Acts like checkUpkeep in a normal Automation job, probably don't need to do anything.
    // Values: Each value in array has to be validated by a contract that chainlink provides.
    function oracleCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    // TODO: one contract for the Market (increase/Decrease/Swap), one each for the other cases.
    // TODO: waiting on exact execution functions.
    function performUpkeep(bytes calldata performData) external {}
}
