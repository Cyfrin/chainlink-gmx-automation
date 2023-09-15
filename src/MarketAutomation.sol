// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibGMXEventLogDecoder} from "./libraries/LibGMXEventLogDecoder.sol";
import {GMXAutomationBase} from "./GMXAutomationBase.sol";
// gmx-synthetics
import {EventUtils} from "gmx-synthetics/event/EventUtils.sol";
import {DataStore} from "gmx-synthetics/data/DataStore.sol";
import {Reader} from "gmx-synthetics/reader/Reader.sol";
import {Market} from "gmx-synthetics/market/Market.sol";
import {OracleUtils} from "gmx-synthetics/oracle/OracleUtils.sol";
import {OrderHandler} from "gmx-synthetics/exchange/OrderHandler.sol";
// chainlink
import {StreamsLookupCompatibleInterface} from
    "chainlink/dev/automation/2_1/interfaces/StreamsLookupCompatibleInterface.sol";
import {ILogAutomation, Log} from "chainlink/dev/automation/2_1/interfaces/ILogAutomation.sol";

/// @title Market Automation - Handles Market Decrease, Increase and Swap cases
/// @author Alex Roan - Cyfrin (@alexroan)
contract MarketAutomation is ILogAutomation, StreamsLookupCompatibleInterface, GMXAutomationBase {
    using LibGMXEventLogDecoder for Log;
    using LibGMXEventLogDecoder for EventUtils.EventLogData;

    // ERRORS
    error MarketAutomation_IncorrectEventName(string eventName, string expectedEventName);
    error MarketAutomation_IncorrectOrderType(uint256 orderType);

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    // Market Swap = 0, Market Increase = 2, Market Decrease = 4
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 = 0;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_2 = 2;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_4 = 4;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIdHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "blockNumber";

    // IMMUTABLES
    OrderHandler public immutable i_orderHandler;

    /// @param dataStore the DataStore contract address - immutable
    /// @param reader the Reader contract address - immutable
    /// @param orderHandler the OrderHandler contract address - immutable
    constructor(DataStore dataStore, Reader reader, OrderHandler orderHandler) GMXAutomationBase(dataStore, reader) {
        i_orderHandler = orderHandler;
    }

    ///////////////////////////
    // AUTOMATION FUNCTIONS
    ///////////////////////////

    /// @notice Retrieve relevant information from the log and perform a feed lookup
    /// @dev Reverts with custom errors if the event name is not equal to the expected event name (OrderCreated), or if the orderType is not equal to the expected orderType [2,4]
    /// @dev In the success case, reverts with StreamsLookup error containing relevant information for the feed lookup
    /// @dev This function is only ever simulated off-chain, so gas is not a concern.
    function checkLog(Log calldata log, bytes memory) external returns (bool, bytes memory) {
        // Decode Event Log 2
        (
            , //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = log.decodeEventLog();

        // Ensure that the event name is equal to the expected event name
        if (keccak256(abi.encode(eventName)) != keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))) {
            revert MarketAutomation_IncorrectEventName(eventName, EXPECTED_LOG_EVENTNAME);
        }

        // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath,,) = eventData.decodeEventData();

        // Revert if the orderType is not equal to one of the expected orderTypes
        if (
            orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 && orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_2
                && orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_4
        ) {
            revert MarketAutomation_IncorrectOrderType(orderType);
        }

        // For each address in:
        // - market
        // - swapPath[]
        // retrieve the Props struct from the DataStore. Use Props.marketToken to retrieve the feedId
        // and add to a list of feedIds.

        // Push the market feedId to the set
        Market.Props memory marketProps = i_reader.getMarket(i_dataStore, market);
        _addPropsToMapping(marketProps);

        // Push the swapPath feedIds to the set
        for (uint256 i = 0; i < swapPath.length; i++) {
            Market.Props memory swapPathProps = i_reader.getMarket(i_dataStore, swapPath[i]);
            _addPropsToMapping(swapPathProps);
        }

        // Clear the feedIdSet
        (string[] memory feedIds, address[] memory addresses) = _flushMapping();

        // Construct the data for the feed lookup lookup error
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedIds,
            STRING_DATASTREAMS_QUERYLABEL,
            log.blockNumber,
            abi.encode(key, addresses)
        );
    }

    /// @notice Check the callback
    /// @dev Encode the values and extra data into performData and return true
    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    /// @notice Perform the upkeep
    /// @param performData the data returned from checkCallback. Encoded:
    ///     - bytes[] values. Each value contains a signed report by the DON, and must be decoded:
    ///         - bytes32[3] memory reportContext,
    ///         - bytes memory reportData,
    ///         - bytes32[] memory rs,
    ///         - bytes32[] memory ss,
    ///         - bytes32 rawVs
    ///     - bytes extraData <- This is where the key and addresses array are stored
    /// @dev Decode the performData and call executeOrder
    function performUpkeep(bytes calldata performData) external onlyForwarder {
        (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
        (bytes32 key, address[] memory addresses) = abi.decode(extraData, (bytes32, address[]));
        OracleUtils.SetPricesParams memory oracleParams;
        oracleParams.realtimeFeedTokens = addresses;
        oracleParams.realtimeFeedData = values;
        i_orderHandler.executeOrder(key, oracleParams);
    }
}
